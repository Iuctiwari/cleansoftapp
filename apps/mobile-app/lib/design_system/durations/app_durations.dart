import 'package:flutter/animation.dart';

abstract final class AppDurations {
  static const Duration instant = Duration.zero;
  static const Duration pressed = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration toggle = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration chart = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Duration splash = Duration(milliseconds: 2200);

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}
