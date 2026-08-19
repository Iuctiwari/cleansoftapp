import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/sizes/app_sizes.dart';

abstract final class AppIconSizes {
  static const double xs = AppSizes.iconExtraSmall;
  static const double sm2 = AppSizes.iconButtonSmall;
  static const double sm = AppSizes.iconSmall;
  static const double md2 = AppSizes.iconCompact;
  static const double md = AppSizes.iconMedium;
  static const double lg2 = AppSizes.iconMediumLarge;
  static const double lg = AppSizes.iconLarge;
  static const double xl2 = AppSizes.iconExtraLarge;
  static const double xl = AppSizes.iconAction;
  static const double xxl = AppSizes.iconHero;
  static const double h = AppSizes.iconHeadline;
  static const double hh = AppSizes.iconHeadlineLarge;
  static const double hero = AppSizes.iconHeroLarge;
  static const double display = AppSizes.iconDisplay;
}

abstract final class AppIconColors {
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;
  static const Color muted = AppColors.textSubtle;
  static const Color onPrimary = AppColors.surface;
  static const Color onDark = AppColors.surface;
}

/// Material equivalents for every Lucide icon used by the exported prototype.
abstract final class AppIcons {
  static const IconData activity = Icons.monitor_heart_outlined;
  static const IconData alert = Icons.error_outline;
  static const IconData arrowBack = Icons.arrow_back;
  static const IconData arrowUpRight = Icons.north_east;
  static const IconData analytics = Icons.bar_chart;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsOff = Icons.notifications_off_outlined;
  static const IconData branch = Icons.business_outlined;
  static const IconData camera = Icons.camera_alt_outlined;
  static const IconData brandCheck = Icons.check;
  static const IconData success = Icons.check_circle_outline;
  static const IconData chevronDown = Icons.keyboard_arrow_down;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData clock = Icons.schedule;
  static const IconData payment = Icons.credit_card_outlined;
  static const IconData money = Icons.attach_money;
  static const IconData edit = Icons.edit_outlined;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData document = Icons.description_outlined;
  static const IconData filter = Icons.filter_list;
  static const IconData key = Icons.key_outlined;
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData checklist = Icons.checklist;
  static const IconData lock = Icons.lock_outline;
  static const IconData logout = Icons.logout;
  static const IconData email = Icons.mail_outline;
  static const IconData location = Icons.location_on_outlined;
  static const IconData message = Icons.chat_bubble_outline;
  static const IconData remove = Icons.remove;
  static const IconData more = Icons.more_horiz;
  static const IconData package = Icons.inventory_2_outlined;
  static const IconData phone = Icons.phone_outlined;
  static const IconData add = Icons.add;
  static const IconData print = Icons.print_outlined;
  static const IconData receipt = Icons.receipt_long_outlined;
  static const IconData refresh = Icons.refresh;
  static const IconData undo = Icons.undo;
  static const IconData search = Icons.search;
  static const IconData settings = Icons.settings_outlined;
  static const IconData share = Icons.share_outlined;
  static const IconData shield = Icons.shield_outlined;
  static const IconData orders = Icons.shopping_bag_outlined;
  static const IconData tag = Icons.sell_outlined;
  static const IconData trendingUp = Icons.trending_up;
  static const IconData trendingDown = Icons.trending_down;
  static const IconData delivery = Icons.local_shipping_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData unlock = Icons.lock_open_outlined;
  static const IconData user = Icons.person_outline;
  static const IconData userVerified = Icons.how_to_reg_outlined;
  static const IconData userAssigned = userVerified;
  static const IconData addUser = Icons.person_add_alt;
  static const IconData users = Icons.group_outlined;
  static const IconData wallet = Icons.account_balance_wallet_outlined;
  static const IconData service = Icons.build_outlined;
  static const IconData close = Icons.close;
  static const IconData quickAction = Icons.bolt;
  static const IconData washingMachine = Icons.local_laundry_service;
  static const IconData dryCleaning = Icons.dry_cleaning;
  static const IconData iron = Icons.iron;
  static const IconData carpet = Icons.square_foot;
}
