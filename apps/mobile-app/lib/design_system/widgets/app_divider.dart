import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/spacing/app_spacing.dart';
import 'package:nexoraa_mobile/design_system/typography/app_text_styles.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final String? dividerLabel = label;
    if (dividerLabel == null) {
      return const Divider();
    }

    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(dividerLabel, style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
