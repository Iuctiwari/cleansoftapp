import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nexoraa_mobile/core/localization/l10n.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

final List<(String Function(AppLocalizations), String)> _services = [
  ((l) => l.serviceWashAndFold, 'laundry'),
  ((l) => l.businessTypeDryCleaning, 'dry_cleaning'),
  ((l) => l.businessTypeTailoring, 'tailoring'),
  ((l) => l.businessTypeShoeCleaning, 'shoe_cleaning'),
  ((l) => l.businessTypeApplianceRepair, 'appliance_repair'),
  ((l) => l.businessTypeMobileRepair, 'mobile_repair'),
  ((l) => l.businessTypeVehicleWash, 'vehicle_wash'),
  ((l) => l.businessTypeSalon, 'salon'),
  ((l) => l.businessTypeGeneral, 'general'),
  ((l) => l.businessTypeCustom, 'custom'),
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
        SnackBar(content: Text(context.l10n.selectAtLeastOneService)),
      );
      return;
    }
    context.pushNamed(AppRouteNames.onboardingInviteStaff, extra: widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 3,
      title: context.l10n.servicesTitle,
      icon: Icons.build_outlined,
      actions: TenantOnboardingActions(
        onBack: context.pop,
        onContinue: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.servicesSubtitle,
            style: const TextStyle(color: kTextSecondary, fontSize: 16, height: 1.45),
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
                label: Text(service.$1(context.l10n)),
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
            context.l10n.servicesSelected(widget.data.selectedServices.length),
            style: const TextStyle(color: kTextSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
