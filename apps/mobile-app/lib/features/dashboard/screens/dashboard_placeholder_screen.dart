import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

class DashboardPlaceholderScreen extends StatelessWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: Text(
              'Dashboard UI will be connected in a future frontend phase.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
