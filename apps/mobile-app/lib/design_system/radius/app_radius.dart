import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 3;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double lgPlus = 10;
  static const double xl = 12;
  static const double xlPlus = 14;
  static const double xxl = 16;
  static const double xxlPlus = 18;
  static const double xxxl = 20;
  static const double sheet = 24;
  static const double hero = 28;
  static const double decorative = 32;
  static const double phone = 44;
  static const double full = 999;

  static const double badge = md;
  static const double chip = xxxl;
  static const double buttonSmall = lgPlus;
  static const double button = xl;
  static const double buttonLarge = xlPlus;
  static const double input = xl;
  static const double card = xxl;
  static const double cardTight = xlPlus;
  static const double dialog = xxxl;
  static const double bottomSheet = sheet;

  static const BorderRadius badgeRadius = BorderRadius.all(
    Radius.circular(badge),
  );
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(dialog),
  );
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(bottomSheet),
  );
  static const BorderRadius circular = BorderRadius.all(Radius.circular(full));

  static BorderRadius avatar(double size) {
    return BorderRadius.all(Radius.circular(size / 2.5));
  }
}
