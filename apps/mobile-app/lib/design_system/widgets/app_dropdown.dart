import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/radius/app_radius.dart';
import 'package:nexoraa_mobile/design_system/sizes/app_sizes.dart';
import 'package:nexoraa_mobile/design_system/spacing/app_spacing.dart';
import 'package:nexoraa_mobile/design_system/typography/app_text_styles.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Token-driven dropdown/select field, styled to match [AppTextField].
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.enabled = true,
    super.key,
  });

  final String label;
  final T value;
  final List<AppDropdownOption<T>> items;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.inputLabel.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          initialValue: value,
          borderRadius: AppRadius.inputRadius,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSubtle,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: icon == null
                ? null
                : Icon(
                    icon,
                    color: AppColors.textSubtle,
                    size: AppSizes.iconMedium,
                  ),
          ),
          items: items
              .map(
                (AppDropdownOption<T> option) => DropdownMenuItem<T>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: enabled
              ? (T? next) {
                  if (next != null) onChanged(next);
                }
              : null,
        ),
      ],
    );
  }
}
