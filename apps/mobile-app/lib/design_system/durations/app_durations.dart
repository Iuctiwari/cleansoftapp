import 'package:flutter/widgets.dart';

@immutable
final class AppTransitionSpec {
  const AppTransitionSpec(this.duration, this.curve);

  final Curve curve;
  final Duration duration;
}

abstract final class AppDurations {
  static const Duration none = Duration.zero;
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration pressed = instant;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration toggle = normal;
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration standard = medium;
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration chart = slow;
  static const Duration delay = Duration(milliseconds: 1200);
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Duration splash = Duration(milliseconds: 2200);
  static const Duration startupSplash = Duration(seconds: 4);

  static const Curve standardCurve = AppCurves.standard;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}

abstract final class AppCurves {
  static const Curve standard = Curves.ease;
  static const Curve linear = Curves.linear;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
}

abstract final class AppTransitions {
  static const AppTransitionSpec color = AppTransitionSpec(
    AppDurations.fast,
    AppCurves.standard,
  );
  static const AppTransitionSpec background = color;
  static const AppTransitionSpec backgroundMedium = AppTransitionSpec(
    AppDurations.normal,
    AppCurves.standard,
  );
  static const AppTransitionSpec backgroundMd = backgroundMedium;
  static const AppTransitionSpec all = color;
  static const AppTransitionSpec press = AppTransitionSpec(
    AppDurations.instant,
    AppCurves.standard,
  );
  static const AppTransitionSpec borderColor = color;
  static const AppTransitionSpec toggleThumb = backgroundMedium;
  static const AppTransitionSpec width = AppTransitionSpec(
    AppDurations.slow,
    AppCurves.standard,
  );
  static const AppTransitionSpec elevation = color;
}

abstract final class AppTransforms {
  static const double pressDown = 0.98;
  static const double pressUp = 1;
  static const Offset centerY = Offset(0, -0.5);
  static const Offset centerX = Offset(-0.5, 0);
}
