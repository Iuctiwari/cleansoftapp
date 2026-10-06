import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// Which branch the shop screens work on (the dashboard's selected branch).
class ShopBranchArgs {
  const ShopBranchArgs({required this.branchId, this.branchName = '', this.businessName = ''});

  final String branchId;
  final String branchName;
  final String businessName;

  /// Falls back to the signed-in user's own branch.
  static ShopBranchArgs from(Object? extra) {
    if (extra is ShopBranchArgs) return extra;
    final session = AuthenticationDependencies.controller.session;
    return ShopBranchArgs(
      branchId: session?.branchId ?? '',
      branchName: session?.branchName ?? '',
      businessName: session?.businessName ?? '',
    );
  }
}

AccessPolicy shopAccessPolicy() => AccessPolicy.fromSession(AuthenticationDependencies.controller.session);

extension ShopErrors on BuildContext {
  /// Error pop-up for the shop's marketplace screens. Unlike the customer
  /// helper, it never touches the customer session.
  Future<void> showShopError(Object error) async {
    if (!mounted) return;
    final String message = consumerError(error);
    await AppAlertDialog.show(this, title: AppAlertDialog.titleFor(message), message: message);
  }
}
