import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// One shop: address, hours, services, Call, Directions and Book.
class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({required this.shopId, this.origin, super.key});

  final String shopId;

  /// Where the customer searched from, so the distance matches the list.
  final ShopSearchFilters? origin;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<ShopDetail> _shop = _fetch();

  Future<ShopDetail> _fetch() => ConsumerDependencies.api.shopDetail(widget.shopId, origin: widget.origin);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopDetail>(
      future: _shop,
      builder: (BuildContext context, AsyncSnapshot<ShopDetail> snapshot) {
        final ShopDetail? shop = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(shop?.shopName ?? '')),
          bottomNavigationBar: shop == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: <Widget>[
                        if (shop.phone.isNotEmpty) ...<Widget>[
                          Expanded(
                            child: SecondaryButton(
                              label: context.l10n.consumerCall,
                              icon: AppIcons.phone,
                              onPressed: () => context.callPhone(shop.phone),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            key: const Key('shop.book'),
                            label: context.l10n.consumerBookService,
                            onPressed: () => context.pushNamed(
                              AppRouteNames.consumerBook,
                              pathParameters: <String, String>{'shopId': shop.shopId},
                              extra: shop,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when snapshot.hasError => AppErrorView(
              message: context.consumerError(snapshot.error!),
              onRetry: () => setState(() {
                _shop = _fetch();
              }),
            ),
            ConnectionState.done => _body(context, shop!),
            _ => const AppLoadingView(),
          },
        );
      },
    );
  }

  Widget _body(BuildContext context, ShopDetail shop) {
    final int today = DateTime.now().weekday % 7; // Dart: Monday = 1 … Sunday = 7
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(shop.shopName, style: AppTextStyles.headingLarge),
                  if (shop.branchName.isNotEmpty) Text(shop.branchName, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Text(
              context.l10n.consumerDistanceKm(shop.distanceKm.toStringAsFixed(1)),
              style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            AppStatusBadge(
              label: shop.isOpenNow ? context.l10n.consumerOpenNow : context.l10n.consumerClosedNow,
              tone: shop.isOpenNow ? AppBadgeTone.success : AppBadgeTone.neutral,
            ),
            if (shop.phone.isNotEmpty)
              InkWell(
                onTap: () => context.callPhone(shop.phone),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(AppIcons.phone, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(shop.phone, style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
          ],
        ),
        if (shop.about != null && shop.about!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          ConsumerSectionTitle(context.l10n.consumerAbout),
          Text(shop.about!, style: AppTextStyles.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.xl),
        ConsumerSectionTitle(context.l10n.consumerServices),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: shop.categories
              .map((ShopCategory c) => Chip(avatar: Icon(categoryIcon(c), size: 18), label: Text(context.categoryLabel(c))))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        ConsumerSectionTitle(context.l10n.consumerHowTheyServe),
        for (final ServiceMode mode in shop.serviceModes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(modeIcon(mode), color: AppColors.primary),
            title: Text(context.modeLabel(mode)),
            subtitle: mode.needsAddress ? Text(context.l10n.consumerTravelsUpTo(shop.serviceRadiusKm)) : null,
          ),
        const SizedBox(height: AppSpacing.md),
        ConsumerSectionTitle(context.l10n.consumerAddressHeading),
        Text(
          <String?>[shop.streetAddress, shop.area, shop.landmark, '${shop.city} ${shop.postalCode}', shop.state]
              .where((String? part) => part != null && part.trim().isNotEmpty)
              .join(', '),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.openDirections(shop.latitude, shop.longitude),
            icon: const Icon(Icons.directions_outlined),
            label: Text(context.l10n.consumerDirections),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConsumerSectionTitle(context.l10n.consumerOpeningHours),
        // Monday first, the way people read a week.
        for (final int day in <int>[1, 2, 3, 4, 5, 6, 0])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.weekdayName(day),
                    style: day == today ? AppTextStyles.labelBold : AppTextStyles.bodyMedium,
                  ),
                ),
                Text(
                  _hoursText(context, shop.hoursFor(day)),
                  style: day == today ? AppTextStyles.labelBold : AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _hoursText(BuildContext context, OpeningHoursDay? day) {
    if (day == null || day.closed || day.open == null || day.close == null) return context.l10n.consumerClosed;
    return '${context.formatClock(day.open!)} – ${context.formatClock(day.close!)}';
  }
}
