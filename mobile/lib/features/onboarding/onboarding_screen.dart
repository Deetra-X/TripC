import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/travel_illustration.dart';

class _Slide {
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.landmark,
    required this.place,
    required this.rating,
  });

  final String title;
  final String subtitle;
  final Landmark landmark;
  final String place;
  final String rating;
}

const _slides = [
  _Slide(
    title: 'Your Ultimate Travel Guide.',
    subtitle: 'Keep travelling anywhere without any hassle.',
    landmark: Landmark.bridge,
    place: 'Ella',
    rating: '4.8',
  ),
  _Slide(
    title: 'Tours Made Just for You.',
    subtitle:
        "Tell us what you love and we'll match you with places "
        "you'll enjoy.",
    landmark: Landmark.stupa,
    place: 'Anuradhapura',
    rating: '4.7',
  ),
  _Slide(
    title: 'Travel Beyond the Crowds.',
    subtitle: 'Discover hidden gems that suit the weather, the time and you.',
    landmark: Landmark.rock,
    place: 'Sigiriya',
    rating: '4.9',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
    // On the last slide this will open interest profiling once that screen
    // exists.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slide = _slides[_page];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => Align(
                    alignment: const Alignment(0, 0.6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TravelIllustration(
                        landmark: _slides[index].landmark,
                        place: _slides[index].place,
                        rating: _slides[index].rating,
                      ),
                    ),
                  ),
                ),
              ),
              _PageIndicator(count: _slides.length, index: _page),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 132),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(_page),
                      children: [
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _onGetStarted,
                child: const Text('Get started'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? colors.secondary : colors.primaryContainer,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
