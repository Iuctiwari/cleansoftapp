import 'package:flutter/widgets.dart';
import 'package:nexoraa_mobile/design_system/icons/app_icons.dart';

/// Central registry for assets currently declared by the Flutter application.
///
/// The Figma export contains no standalone logo file, so its existing vector
/// check-mark glyph is mapped to the bundled Material icon font.
abstract final class AppAssets {
  static const String environment = '.env';
  static const IconData logo = AppIcons.brandCheck;
  static const IconData appLogo = logo;
  static const IconData splashLogo = logo;
}
