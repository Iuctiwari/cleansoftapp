import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';

/// A salon booking's services, who does each one and when, with the total.
/// Pass [onChange] to show a "Change" button on each service (owner only).
class SalonPartsView extends StatelessWidget {
  const SalonPartsView({required this.booking, this.onChange, super.key});

  final SalonBooking booking;
  final void Function(SalonBookedPart part)? onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final SalonBookedPart part in booking.parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${part.name} · ${rupees(part.price)}', style: AppTextStyles.title),
                      Text(
                        '${part.staffName} (${part.role}) · ${context.formatClock(part.start)} – ${context.formatClock(part.end)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onChange != null)
                  TextButton(
                    key: Key('salon.part.change.${part.serviceId}'),
                    onPressed: () => onChange!(part),
                    child: const Text('Change'),
                  ),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: <Widget>[
            Expanded(child: Text('Total · ${durationText(booking.totalMinutes)}', style: AppTextStyles.labelBold)),
            Text(rupees(booking.totalPrice), style: AppTextStyles.labelBold),
          ],
        ),
        Text('Pay at the salon after the service. No advance.', style: AppTextStyles.caption),
      ],
    );
  }
}
