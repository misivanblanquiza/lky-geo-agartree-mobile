import 'package:flutter/painting.dart';

/// Approved brand palette. Only `AppTheme` should read these; feature widgets
/// use `Theme.of(context).colorScheme` so the later logo/typography pass maps
/// into one place.
abstract final class AppPalette {
  /// Main actions, selected states, map emphasis. 7.86:1 on [background].
  static const Color primary = Color(0xFF005850);

  /// Decorative fill only. 1.86:1 on [background]: never text, and never an
  /// information-only indicator. Pair with tertiary text/icons.
  static const Color secondary = Color(0xFFD2B577);

  /// App canvas and light surfaces.
  static const Color background = Color(0xFFF8F8F6);

  /// High-contrast text and icons. 12.13:1 on [background], 6.52:1 on [secondary].
  static const Color tertiary = Color(0xFF3D2F22);
}

abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

abstract final class AppSizes {
  /// Minimum actionable touch target (design doc: 44 dp).
  static const double minTouchTarget = 44;
  static const double radius = 12;
}
