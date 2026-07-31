import 'package:flutter/widgets.dart';

import '../colors/app_colors.dart';

abstract final class AppShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> small = <BoxShadow>[
    BoxShadow(
      color: AppColors.blackOverlay06,
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: AppColors.blackOverlay04,
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: AppColors.blackOverlay05,
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> control = <BoxShadow>[
    BoxShadow(
      color: AppColors.blackOverlay20,
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> medium = <BoxShadow>[
    BoxShadow(
      color: AppColors.blackOverlay10,
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> selected = <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryOverlay25,
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryOverlay45,
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> modal = <BoxShadow>[
    BoxShadow(
      color: AppColors.blackOverlay20,
      offset: Offset(0, 8),
      blurRadius: 32,
    ),
  ];
  static const List<BoxShadow> bottomSheet = modal;

  static const List<BoxShadow> mobileFrame = <BoxShadow>[
    BoxShadow(
      color: AppColors.blackOverlay35,
      offset: Offset(0, 32),
      blurRadius: 80,
    ),
    BoxShadow(color: AppColors.blackOverlay10, spreadRadius: 1),
  ];
}
