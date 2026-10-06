import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/online_requests/models/shop_marketplace_models.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';

/// Dashboard card for the selected branch: the Online requests entry with its
/// waiting count, plus the "add your shop address" banner and one-time pop-up
/// while the listing is incomplete (owners and branch managers only).
class OnlineRequestsCard extends StatefulWidget {
  const OnlineRequestsCard({required this.branch, this.serviceFactory, super.key});

  final ShopBranchArgs branch;

  /// For tests.
  final ShopMarketplaceApiService Function(String branchId)? serviceFactory;

  /// The pop-up is shown at most once per app session.
  static bool addressPromptShown = false;

  @override
  State<OnlineRequestsCard> createState() => _OnlineRequestsCardState();
}

class _OnlineRequestsCardState extends State<OnlineRequestsCard> {
  ShopRequestSummary? _summary;
  ShopListing? _listing;

  AccessPolicy get _policy => AccessPolicy.fromSession(AuthenticationDependencies.controller.session);
  bool get _canSeeRequests => _policy.allows(AppCapability.ordersView);
  bool get _canEditListing => _policy.allows(AppCapability.branchesEdit);
  bool get _validBranch => widget.branch.branchId.isNotEmpty && widget.branch.branchId != 'unavailable';

  ShopMarketplaceApiService _service() =>
      widget.serviceFactory?.call(widget.branch.branchId) ??
      ShopMarketplaceApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
        branchId: widget.branch.branchId,
      );

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(OnlineRequestsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch.branchId != widget.branch.branchId) {
      _summary = null;
      _listing = null;
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (!_validBranch) return;
    final ShopMarketplaceApiService api = _service();
    // Both are best-effort: the dashboard must never fail because of them.
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      if (_canSeeRequests) api.summary().then<Object?>((ShopRequestSummary s) => s).catchError((Object _) => null),
      if (_canEditListing) api.getListing().then<Object?>((ShopListing l) => l).catchError((Object _) => null),
    ]);
    if (!mounted) return;
    setState(() {
      for (final Object? result in results) {
        if (result is ShopRequestSummary) _summary = result;
        if (result is ShopListing) _listing = result;
      }
    });
    if ((_listing?.needsAddress ?? false) && !OnlineRequestsCard.addressPromptShown) {
      OnlineRequestsCard.addressPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_showAddressPrompt()));
    }
  }

  Future<void> _showAddressPrompt() async {
    if (!mounted) return;
    final bool? add = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 40),
        title: Text(dialogContext.l10n.shopAddressPromptTitle, textAlign: TextAlign.center),
        content: Text(dialogContext.l10n.shopAddressPromptBody, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.shopAddressPromptLater),
          ),
          FilledButton(
            key: const Key('addressPrompt.add'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.shopAddressPromptAction),
          ),
        ],
      ),
    );
    if (add == true && mounted) await _openListing();
  }

  Future<void> _openListing() async {
    await context.pushNamed(AppRouteNames.shopListing, extra: widget.branch);
    unawaited(_refresh());
  }

  Future<void> _openRequests() async {
    await context.pushNamed(AppRouteNames.onlineRequests, extra: widget.branch);
    unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    if (!_validBranch || (!_canSeeRequests && !_canEditListing)) return const SizedBox.shrink();
    final int waiting = _summary?.pending ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_canEditListing && (_listing?.needsAddress ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Material(
                color: AppColors.warningSurface,
                borderRadius: AppRadius.cardRadius,
                child: InkWell(
                  key: const Key('dashboard.addShopAddress'),
                  borderRadius: AppRadius.cardRadius,
                  onTap: _openListing,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: <Widget>[
                        const Icon(AppIcons.location, color: AppColors.warningText),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                context.l10n.shopAddressPromptTitle,
                                style: AppTextStyles.labelBold.copyWith(color: AppColors.warningText),
                              ),
                              Text(context.l10n.shopAddressPromptBody, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(AppIcons.chevronRight, color: AppColors.warningText),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_canSeeRequests)
            AppCard(
              key: const Key('dashboard.onlineRequests'),
              onTap: _openRequests,
              borderColor: waiting > 0 ? AppColors.primaryBorder : null,
              child: Row(
                children: <Widget>[
                  Badge(
                    isLabelVisible: waiting > 0,
                    label: Text('$waiting'),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(context.l10n.onlineRequestsTitle, style: AppTextStyles.title),
                        Text(
                          waiting > 0
                              ? context.l10n.onlineRequestsWaiting(waiting)
                              : context.l10n.onlineRequestsCardSubtitle,
                          style: waiting > 0
                              ? AppTextStyles.labelBold.copyWith(color: AppColors.primary)
                              : AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
