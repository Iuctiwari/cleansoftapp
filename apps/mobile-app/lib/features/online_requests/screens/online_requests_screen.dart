import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/online_requests/models/shop_marketplace_models.dart';
import 'package:nexoraa_mobile/features/online_requests/screens/shop_request_detail_screen.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';

/// The shop's "Online requests" module for one branch.
class OnlineRequestsScreen extends StatefulWidget {
  const OnlineRequestsScreen({required this.branch, this.service, super.key});

  final ShopBranchArgs branch;
  final ShopMarketplaceApiService? service;

  @override
  State<OnlineRequestsScreen> createState() => _OnlineRequestsScreenState();
}

class _OnlineRequestsScreenState extends State<OnlineRequestsScreen> {
  late final ShopMarketplaceApiService _api =
      widget.service ??
      ShopMarketplaceApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
        branchId: widget.branch.branchId,
      );

  /// Waiting first: that is what the shop has to act on.
  RequestStatus? _status = RequestStatus.pending;
  late Future<ShopRequestPage> _requests = _fetch();
  ShopRequestSummary? _summary;

  Future<ShopRequestPage> _fetch() {
    _api.summary().then((ShopRequestSummary s) {
      if (mounted) setState(() => _summary = s);
    }).catchError((Object _) {});
    return _api.listRequests(status: _status?.code);
  }

  void _reload() {
    setState(() {
      _requests = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.onlineRequestsTitle),
        bottom: widget.branch.branchName.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(widget.branch.branchName, style: AppTextStyles.caption),
                ),
              ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              children: <Widget>[
                for (final RequestStatus? status in <RequestStatus?>[
                  RequestStatus.pending,
                  RequestStatus.accepted,
                  RequestStatus.completed,
                  RequestStatus.declined,
                  RequestStatus.cancelled,
                  RequestStatus.expired,
                  null,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(_chipLabel(context, status)),
                      selected: _status == status,
                      onSelected: (_) {
                        _status = status;
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<ShopRequestPage>(
              future: _requests,
              builder: (BuildContext context, AsyncSnapshot<ShopRequestPage> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const AppLoadingView();
                if (snapshot.hasError) {
                  return AppErrorView(message: context.consumerError(snapshot.error!), onRetry: _reload);
                }
                final List<ShopRequest> items = snapshot.data!.items;
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: items.isEmpty
                      ? ListView(
                          children: <Widget>[
                            const SizedBox(height: AppSpacing.section),
                            AppEmptyState(
                              icon: AppIcons.orders,
                              title: context.l10n.onlineRequestsEmptyTitle,
                              message: context.l10n.onlineRequestsEmptyMessage,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (BuildContext context, int index) => _ShopRequestCard(
                            request: items[index],
                            onOpen: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => ShopRequestDetailScreen(
                                    requestId: items[index].requestId,
                                    branch: widget.branch,
                                    service: _api,
                                  ),
                                ),
                              );
                              _reload();
                            },
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _chipLabel(BuildContext context, RequestStatus? status) {
    if (status == null) return context.l10n.consumerFilterAll;
    final String label = context.statusLabel(status);
    final int? count = switch (status) {
      RequestStatus.pending => _summary?.pending,
      RequestStatus.accepted => _summary?.accepted,
      _ => null,
    };
    return count == null || count == 0 ? label : '$label ($count)';
  }
}

class _ShopRequestCard extends StatelessWidget {
  const _ShopRequestCard({required this.request, required this.onOpen});

  final ShopRequest request;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ServiceRequest r = request.base;
    final DateTime? date = DateTime.tryParse(r.preferredDate);
    return AppCard(
      onTap: onOpen,
      borderColor: r.status == RequestStatus.pending ? AppColors.warningBorder : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(request.customerName, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              AppStatusBadge(label: context.statusLabel(r.status), tone: statusTone(r.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Icon(modeIcon(r.requestType), size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${context.categoryLabel(r.category)} · ${context.modeLabel(r.requestType)}'
                  '${request.distanceKm == null ? '' : ' · ${context.l10n.consumerDistanceKm(request.distanceKm!.toStringAsFixed(1))}'}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(r.description, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(AppIcons.clock, size: 16, color: AppColors.textSubtle),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  r.confirmedAt != null
                      ? context.formatDateTime(r.confirmedAt!)
                      : '${date == null ? r.preferredDate : context.formatDay(date)}, '
                            '${context.formatClock(r.slotStart)} – ${context.formatClock(r.slotEnd)}',
                  style: AppTextStyles.caption,
                ),
              ),
              Text(r.requestNumber, style: AppTextStyles.micro),
            ],
          ),
        ],
      ),
    );
  }
}
