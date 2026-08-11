import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

const _services = <(String, String)>[
  ('Wash & Fold', 'laundry'),
  ('Dry Cleaning', 'dry_cleaning'),
  ('Tailoring', 'tailoring'),
  ('Shoe Cleaning', 'shoe_cleaning'),
  ('Appliance Repair', 'appliance_repair'),
  ('Mobile Repair', 'mobile_repair'),
  ('Vehicle Wash', 'vehicle_wash'),
  ('Salon', 'salon'),
  ('General', 'general'),
  ('Custom', 'custom'),
];

class ServicesScreen extends StatefulWidget {
  final TenantOnboardingData data;

  const ServicesScreen({super.key, required this.data});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  void _toggle(String service) {
    setState(() {
      if (!widget.data.selectedServices.add(service)) {
        widget.data.selectedServices.remove(service);
      }
    });
  }

  void _continue() {
    if (widget.data.selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service')),
      );
      return;
    }
    context.pushNamed(AppRouteNames.onboardingInviteStaff, extra: widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 3,
      title: 'Services',
      icon: Icons.build_outlined,
      actions: TenantOnboardingActions(
        onBack: context.pop,
        onContinue: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select the services your business offers. You can add more later.',
            style: TextStyle(color: kTextSecondary, fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _services.map((service) {
              final selected = widget.data.selectedServices.contains(
                service.$2,
              );
              return FilterChip(
                selected: selected,
                showCheckmark: true,
                checkmarkColor: kPrimary,
                label: Text(service.$1),
                onSelected: (_) => _toggle(service.$2),
                backgroundColor: kSurface,
                selectedColor: kPrimaryLight,
                side: BorderSide(
                  color: selected ? kPrimary : kBorder,
                  width: selected ? 1.6 : 1,
                ),
                labelStyle: TextStyle(
                  color: selected ? kPrimary : kTextPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Text(
            '${widget.data.selectedServices.length} services selected',
            style: const TextStyle(color: kTextSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
