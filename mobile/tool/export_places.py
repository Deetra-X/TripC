"""Export the places spreadsheet to the JSON the app loads.

Usage (from mobile/):
    python tool/export_places.py [path/to/places.xlsx] [path/to/places.json]

Defaults to assets/Map/sri_lanka_places_v3.xlsx -> assets/data/places.json.
Re-run it after editing the spreadsheet. Column names are kept as they are,
so the app reads Supabase rows the same way once the database is live.
Only the Python standard library is needed.
"""

import json
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter
from pathlib import Path

NS = {
    'm': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
}

TAGS = [
    'tag_nature', 'tag_hiking', 'tag_scenic', 'tag_culture_history',
    'tag_religious', 'tag_beach', 'tag_wildlife', 'tag_nightlife', 'tag_family',
]
TEXT = [
    'province', 'district', 'category', 'place_name', 'entry_type',
    'description', 'google_place_id', 'indoor_outdoor', 'monsoon_zone',
]

# Rough bounding box of Sri Lanka, to catch swapped or mistyped coordinates.
LAT_RANGE = (5.7, 10.0)
LNG_RANGE = (79.4, 82.1)


def read_sheet(path, name):
    book = zipfile.ZipFile(path)
    workbook = ET.fromstring(book.read('xl/workbook.xml'))
    rels = ET.fromstring(book.read('xl/_rels/workbook.xml.rels'))
    targets = {rel.get('Id'): rel.get('Target') for rel in rels}
    shared = []
    if 'xl/sharedStrings.xml' in book.namelist():
        strings = ET.fromstring(book.read('xl/sharedStrings.xml'))
        for item in strings.findall('m:si', NS):
            shared.append(''.join(t.text or '' for t in item.iter(f'{{{NS["m"]}}}t')))

    sheet_path = None
    for sheet in workbook.find('m:sheets', NS):
        if sheet.get('name') == name:
            target = targets[sheet.get(f'{{{NS["r"]}}}id')].lstrip('/')
            sheet_path = target if target.startswith('xl/') else f'xl/{target}'
    if sheet_path is None:
        sys.exit(f'No sheet called "{name}" in {path}')

    def column(ref):
        index = 0
        for letter in re.match(r'[A-Z]+', ref).group():
            index = index * 26 + ord(letter) - 64
        return index - 1

    rows = []
    for row in ET.fromstring(book.read(sheet_path)).find('m:sheetData', NS):
        cells = {}
        for cell in row:
            value = cell.find('m:v', NS)
            if cell.get('t') == 's' and value is not None:
                cells[column(cell.get('r'))] = shared[int(value.text)]
            elif cell.get('t') == 'inlineStr':
                cells[column(cell.get('r'))] = ''.join(
                    t.text or '' for t in cell.iter(f'{{{NS["m"]}}}t'))
            elif value is not None:
                cells[column(cell.get('r'))] = value.text
        rows.append([cells.get(i) for i in range(max(cells) + 1)] if cells else [])
    header = rows[0]
    return [dict(zip(header, row + [None] * (len(header) - len(row)))) for row in rows[1:]]


def text(value):
    if value is None:
        return None
    value = str(value).strip()
    return value or None


def number(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def flag(value):
    """1/0, yes/no or Y/N as true/false; anything else as null."""
    value = (text(value) or '').lower()
    if value in ('1', 'yes', 'y', 'true'):
        return True
    if value in ('0', 'no', 'n', 'false'):
        return False
    return None


def clock(value):
    """'7.30', '18.00' or '3,00' as '07:30', '18:00', '03:00'."""
    value = text(value)
    if value is None:
        return None
    match = re.fullmatch(r'(\d{1,2})[.:,](\d{2})', value)
    if not match or int(match[1]) > 23 or int(match[2]) > 59:
        return None
    return f'{int(match[1]):02d}:{match[2]}'


def main():
    source = Path(sys.argv[1] if len(sys.argv) > 1 else 'assets/Map/sri_lanka_places_v3.xlsx')
    output = Path(sys.argv[2] if len(sys.argv) > 2 else 'assets/data/places.json')
    rows = read_sheet(source, 'places')

    places, warnings = [], []
    for row in rows:
        name = text(row.get('place_name'))
        if name is None:
            continue  # Empty placeholder rows for hidden gems.
        lat, lng = number(row.get('latitude')), number(row.get('longitude'))
        if (lat is None) != (lng is None):
            warnings.append(f'{name}: only one of latitude/longitude is filled')
            lat = lng = None
        if lat is not None and not (LAT_RANGE[0] <= lat <= LAT_RANGE[1] and LNG_RANGE[0] <= lng <= LNG_RANGE[1]):
            warnings.append(f'{name}: ({lat}, {lng}) is outside Sri Lanka; left off the map')
            lat = lng = None
        for key in ('open_time', 'close_time'):
            if text(row.get(key)) and clock(row.get(key)) is None:
                warnings.append(f'{name}: {key} "{row.get(key)}" is not a time like 07:30')

        place_id = number(row.get('place_id'))
        rating = number(row.get('avg_rating'))
        bayesian = number(row.get('bayesian_rating'))
        score = number(row.get('rating_score_0_1'))
        reviews = number(row.get('review_count'))
        place = {
            'place_id': int(place_id) if place_id is not None else None,
            **{key: text(row.get(key)) for key in TEXT},
            'latitude': lat,
            'longitude': lng,
            **{tag: bool(flag(row.get(tag))) for tag in TAGS},
            'rain_sensitive': flag(row.get('rain_sensitive')),
            'open_time': clock(row.get('open_time')),
            'close_time': clock(row.get('close_time')),
            'avg_rating': round(rating, 2) if rating is not None else None,
            'review_count': int(reviews) if reviews is not None else None,
            'bayesian_rating': round(bayesian, 4) if bayesian is not None else None,
            'rating_score_0_1': round(score, 4) if score is not None else None,
            'hidden_gem': flag(row.get('hidden_gem')),
        }
        places.append(place)

    ids = Counter(p['place_id'] for p in places if p['place_id'] is not None)
    for place_id, count in sorted(ids.items()):
        if count > 1:
            warnings.append(f'place_id {place_id} is used by {count} places')
    for place in places:
        if place['place_id'] is None:
            warnings.append(f'{place["place_name"]}: no place_id')

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(places, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')

    mapped = sum(1 for p in places if p['latitude'] is not None)
    print(f'Wrote {len(places)} places to {output} ({mapped} with coordinates).')
    print('By category:', dict(Counter(p['category'] for p in places).most_common()))
    if warnings:
        print(f'{len(warnings)} things to check in the spreadsheet:')
        for warning in warnings:
            print('  -', warning)


if __name__ == '__main__':
    main()
