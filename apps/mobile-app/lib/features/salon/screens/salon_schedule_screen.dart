import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';

/// One day of the salon: each team member with the appointments they have.
class SalonScheduleScreen extends StatefulWidget {
  const SalonScheduleScreen({required this.branch, this.service, super.key});

  final ShopBranchArgs branch;
  final ShopMarketplaceApiService? service;

  @override
  State<SalonScheduleScreen> createState() => _SalonScheduleScreenState();
}

class _SalonScheduleScreenState extends State<SalonScheduleScreen> {
  late final ShopMarketplaceApiService _api =
      widget.service ??
      ShopMarketplaceApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
        branchId: widget.branch.branchId,
      );

  DateTime _date = DateUtils.dateOnly(DateTime.now());
  late Future<SalonSchedule> _schedule = _fetch();

  String get _key => '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<SalonSchedule> _fetch() => _api.salonSchedule(_key);

  void _move(int days) {
    setState(() {
      _date = _date.add(Duration(days: days));
      _schedule = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salon schedule')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                IconButton(
                  key: const Key('salon.schedule.prev'),
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(child: Text(context.formatDay(_date), style: AppTextStyles.headingSmall)),
                ),
                IconButton(
                  key: const Key('salon.schedule.next'),
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<SalonSchedule>(
              future: _schedule,
              builder: (BuildContext context, AsyncSnapshot<SalonSchedule> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const AppLoadingView();
                if (snapshot.hasError) {
                  return AppErrorView(
                    message: context.consumerError(snapshot.error!),
                    onRetry: () => setState(() => _schedule = _fetch()),
                  );
                }
                final SalonSchedule schedule = snapshot.data!;
                if (schedule.staff.isEmpty) {
                  return const Center(child: Text('Add your team in Salon team & services first.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    if (schedule.closed)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text('The salon is closed this day.'),
                      ),
                    for (final SalonStaffDay day in schedule.staff)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(day.staff.name, style: AppTextStyles.title),
                              Text(day.staff.role, style: AppTextStyles.caption),
                              const SizedBox(height: AppSpacing.sm),
                              if (day.appointments.isEmpty) const Text('Free all day'),
                              for (final SalonAppointment a in day.appointments)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: <Widget>[
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          '${context.formatClock(a.start)} – ${context.formatClock(a.end)}',
                                          style: AppTextStyles.labelBold,
                                        ),
                                      ),
                                      Expanded(child: Text('${a.service} · ${a.customerName}')),
                                      AppStatusBadge(
                                        label: a.status,
                                        tone: a.status == 'Accepted' ? AppBadgeTone.success : AppBadgeTone.neutral,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
