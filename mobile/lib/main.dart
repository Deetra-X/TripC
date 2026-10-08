import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/auth/auth_service.dart';
import 'core/theme/theme_controller.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/manrope/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Manrope'], license);
  });

  runApp(TripCApp(auth: AuthService(), themeMode: ThemeController()));
}
