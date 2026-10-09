import 'dart:async';

import 'package:nexoraa_mobile/features/consumer/widgets/text_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/core/push/push_dependencies.dart';
import 'package:nexoraa_mobile/core/push/push_platform.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// One of the customer's requests: status, shop reply, history, cancel.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({required this.requestId, this.pushes, super.key});

  final String requestId;

  /// Pushes that arrive while the app is open; defaults to the app's own.
  final Stream<PushPayload>? pushes;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Future<ServiceRequest> _request = _fetch();
  bool _cancelling = false;
  StreamSubscription<PushPayload>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    // The shop answered this very request while it is open: show the answer.
    _pushSubscription = (widget.pushes ?? PushDependencies.registrar.arrivals).listen((
      PushPayload payload,
    ) {
      if (payload.data['requestId'] == widget.requestId) _reload();
    });
  }

  @override
  void dispose() {
    unawaited(_pushSubscription?.cancel());
    super.dispose();
  }

  Future<ServiceRequest> _fetch() => ConsumerDependencies.api.getRequest(widget.requestId);

  void _reload() {
    setState(() {
      _request = _fetch();
    });
  }

  Future<void> _cancel(ServiceRequest request) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => TextPromptDialog(
        title: dialogContext.l10n.consumerCancelConfirm,
        hint: dialogContext.l10n.consumerCancelReasonHint,
        confirmLabel: dialogContext.l10n.consumerCancelRequest,
        cancelLabel: dialogContext.l10n.consumerKeepRequest,
        destructive: true,
        confirmKey: const Key('cancel.confirm'),
      ),
    );
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final ServiceRequest updated = await ConsumerDependencies.api.cancelRequest(request.requestId, reason: reason);
      if (mounted) {
        setState(() {
          _request = Future<ServiceRequest>.value(updated);
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _cancelling = false);
      if (mounted) await context.showConsumerError(error);
      _reload();
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.consumerRequestDetails)),
      body: FutureBuilder<ServiceRequest>(
        future: _request,
        builder: (BuildContext context, AsyncSnapshot<ServiceRequest> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const AppLoadingView();
          if (snapshot.hasError) {
            return AppErrorView(message: context.consumerError(snapshot.error!), onRetry: _reload);
          }
          final ServiceRequest request = snapshot.data!;
          final DateTime? date = DateTime.tryParse(request.preferredDate);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(request.shopName, style: AppTextStyles.headingLarge)),
                    AppStatusBadge(label: context.statusLabel(request.status), tone: statusTone(request.status)),
                  ],
                ),
                Text(request.requestNumber, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.lg),
                ..._statusMessage(context, request),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _row(categoryIcon(request.category), context.categoryLabel(request.category)),
                      _row(modeIcon(request.requestType), context.modeLabel(request.requestType)),
                      _row(
                        AppIcons.clock,
                        '${context.l10n.consumerPreferredTime}: '
                        '${date == null ? request.preferredDate : context.formatDay(date)}, '
                        '${context.formatClock(request.slotStart)} – ${context.formatClock(request.slotEnd)}',
                      ),
                      if (request.addressFormatted != null)
                        _row(AppIcons.location, request.addressFormatted!),
                      const Divider(),
                      Text(request.description, style: AppTextStyles.bodyMedium),
                      if (request.items.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Text(context.l10n.consumerItems, style: AppTextStyles.labelBold),
                        for (final RequestItem item in request.items)
                          Text('• ${item.name} × ${item.quantity}', style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (request.shopPhone.isNotEmpty)
                  SecondaryButton(
                    label: context.l10n.consumerCallShop,
                    icon: AppIcons.phone,
                    onPressed: () => context.callPhone(request.shopPhone),
                  ),
                if (request.canCancel) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    key: const Key('request.cancel'),
                    onPressed: _cancelling ? null : () => _cancel(request),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: Text(context.l10n.consumerCancelRequest),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ConsumerSectionTitle(context.l10n.consumerHistory),
                for (final RequestHistoryEntry entry in request.history.reversed) _historyTile(context, entry),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _statusMessage(BuildContext context, ServiceRequest request) {
    Widget box(String title, String? body, Color color, Color surface) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(color: surface, borderRadius: AppRadius.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTextStyles.labelBold.copyWith(color: color)),
              if (body != null && body.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: AppTextStyles.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );

    return switch (request.status) {
      RequestStatus.pending => <Widget>[
        box(
          context.l10n.requestStatusPending,
          request.expiresAt == null ? null : context.l10n.consumerReplyBy(context.formatDateTime(request.expiresAt!)),
          AppColors.warningText,
          AppColors.warningSurface,
        ),
      ],
      RequestStatus.accepted || RequestStatus.completed => <Widget>[
        if (request.confirmedAt != null)
          box(
            context.l10n.consumerConfirmedTime,
            context.formatDateTime(request.confirmedAt!),
            AppColors.successDark,
            AppColors.successSurface,
          ),
        if (request.shopNote != null) box(context.l10n.consumerShopMessage, request.shopNote, AppColors.primary, AppColors.primarySurface),
        if (request.orderNumber != null)
          box(context.l10n.consumerOrderCreated(request.orderNumber!), null, AppColors.primary, AppColors.primarySurface),
      ],
      RequestStatus.declined => <Widget>[
        box(context.l10n.requestStatusDeclined, request.declineReason, AppColors.errorText, AppColors.errorSurface),
      ],
      RequestStatus.cancelled => <Widget>[
        if (request.cancelReason != null)
          box(context.l10n.consumerReason, request.cancelReason, AppColors.textSecondary, AppColors.surfaceMuted),
      ],
      RequestStatus.expired => <Widget>[
        box(context.l10n.requestStatusExpired, null, AppColors.textSecondary, AppColors.surfaceMuted),
      ],
    };
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.textSubtle),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    ),
  );

  Widget _historyTile(BuildContext context, RequestHistoryEntry entry) {
    final String by = switch (entry.by) {
      'customer' => context.l10n.consumerByYou,
      'shop' => context.l10n.consumerByShop,
      _ => context.l10n.consumerByAutomatic,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: AppColors.primary.withValues(alpha: 0.7)),
      title: Text('${context.statusLabel(entry.status)} · $by', style: AppTextStyles.labelBold),
      subtitle: Text(
        <String>[context.formatDateTime(entry.at), if (entry.note != null) entry.note!].join('\n'),
        style: AppTextStyles.caption,
      ),
    );
  }
}
