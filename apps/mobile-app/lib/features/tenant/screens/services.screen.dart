import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

const _services = <String>[
  'Wash & Fold',
  'Dry Cleaning',
  'Ironing',
  'Tailoring',
  'Shoe Cleaning',
  'Carpet Cleaning',
  'Express Service',
  'Pickup & Delivery',
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

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 3,
      title: 'Services',
      icon: Icons.build_outlined,
      actions: TenantOnboardingActions(
        onBack: context.pop,
        onContinue: () => context.pushNamed(
          AppRouteNames.onboardingInviteStaff,
          extra: widget.data,
        ),
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
              final selected = widget.data.selectedServices.contains(service);
              return FilterChip(
                selected: selected,
                showCheckmark: true,
                checkmarkColor: kPrimary,
                label: Text(service),
                onSelected: (_) => _toggle(service),
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
