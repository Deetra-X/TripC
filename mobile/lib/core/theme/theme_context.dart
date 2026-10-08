import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// TripC colour roles for the current theme.
  TripCColors get colors =>
      Theme.of(this).extension<TripCColors>() ??
      (isDark ? TripCColors.dark : TripCColors.light);

  TextTheme get text => Theme.of(this).textTheme;

  /// Status bar icons that stay legible on the current background.
  SystemUiOverlayStyle get overlayStyle =>
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}
