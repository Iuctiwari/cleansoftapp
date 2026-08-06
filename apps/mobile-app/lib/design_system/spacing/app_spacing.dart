import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double xsPlus = 5;
  static const double sm = 6;
  static const double smPlus = 7;
  static const double md = 8;
  static const double mdPlus = 10;
  static const double lg = 12;
  static const double lgPlus = 14;
  static const double xl = 16;
  static const double xlPlus = 18;
  static const double xxl = 20;
  static const double xxlPlus = 24;
  static const double xxxl = 28;
  static const double section = 32;
  static const double sectionLarge = 36;
  static const double display = 40;
  static const double displayLarge = 48;
  static const double topBar = 52;
  static const double controlLarge = 56;
  static const double block = 64;
  static const double header = 72;

  static const double pageHorizontal = xl;
  static const double pageBottom = xxlPlus;
  static const double cardPadding = xl;
  static const double cardPaddingTight = lg;
  static const double sectionGap = xl;
  static const double sectionGapLarge = xxl;
  static const double formGroupGap = lg;
  static const double formSectionGap = lgPlus;
  static const double listGap = mdPlus;
  static const double inputHorizontal = lgPlus;
  static const double inputVertical = lg;
  static const double inputWithIcon = display;
  static const double listTileVertical = lgPlus;
  static const double listTileHorizontal = xl;
  static const double bottomNavTop = mdPlus;
  static const double bottomNavBottom = xs;
  static const double bottomNavExtra = md;
  static const double headerHorizontal = xxl;
  static const double headerBottom = xxl;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    pageHorizontal,
    topBar,
    pageHorizontal,
    pageBottom,
  );
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets inputInsets = EdgeInsets.symmetric(
    horizontal: inputHorizontal,
    vertical: inputVertical,
  );
  static const EdgeInsets buttonLargeInsets = EdgeInsets.symmetric(
    horizontal: xxlPlus,
    vertical: xl,
  );
  static const EdgeInsets buttonMediumInsets = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: 13,
  );
  static const EdgeInsets buttonSmallInsets = EdgeInsets.symmetric(
    horizontal: lgPlus,
    vertical: md,
  );
}

abstract final class AppPadding {
  static const double pagePaddingHorizontal = AppSpacing.pageHorizontal;
  static const double pagePaddingTop = AppSpacing.topBar;
  static const double pagePaddingBottom = AppSpacing.pageBottom;
  static const double cardPadding = AppSpacing.cardPadding;
  static const double cardPaddingTight = AppSpacing.cardPaddingTight;
  static const double sectionGap = AppSpacing.sectionGap;
  static const double sectionGapLarge = AppSpacing.sectionGapLarge;
  static const double formGroupGap = AppSpacing.formGroupGap;
  static const double formSectionGap = AppSpacing.formSectionGap;
  static const double inputPaddingVertical = AppSpacing.inputVertical;
  static const double inputPaddingHorizontal = AppSpacing.inputHorizontal;
  static const double inputPaddingIcon = AppSpacing.inputWithIcon;
  static const double listTilePaddingVertical = AppSpacing.listTileVertical;
  static const double listTilePaddingHorizontal = AppSpacing.listTileHorizontal;
  static const double listGap = AppSpacing.listGap;
  static const EdgeInsets page = AppSpacing.pagePadding;
  static const EdgeInsets card = AppSpacing.cardInsets;
  static const EdgeInsets input = AppSpacing.inputInsets;
  static const EdgeInsets buttonLarge = AppSpacing.buttonLargeInsets;
  static const EdgeInsets buttonMedium = AppSpacing.buttonMediumInsets;
  static const EdgeInsets buttonSmall = AppSpacing.buttonSmallInsets;
}

abstract final class AppGrid {
  static const double columns2Gap = AppSpacing.mdPlus;
  static const double columns3Gap = AppSpacing.mdPlus;
  static const double columns4Gap = AppSpacing.mdPlus;
  static const double mobileWidth = 390;
  static const double mobileHeight = 844;
  static const int zBackground = 0;
  static const int zBase = 10;
  static const int zCard = 20;
  static const int zTopBar = 40;
  static const int zBottomNavigation = 50;
  static const int zFloatingActionButton = 60;
  static const int zNotch = 100;
}
