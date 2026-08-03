import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/icons/app_icons.dart';
import 'package:nexoraa_mobile/design_system/sizes/app_sizes.dart';
import 'package:nexoraa_mobile/design_system/spacing/app_spacing.dart';
import 'package:nexoraa_mobile/design_system/typography/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.autofillHints,
    this.hintText,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    super.key,
  });

  final Iterable<String>? autofillHints;
  final TextEditingController controller;
  final String? hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String label;
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction? textInputAction;

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
        TextFormField(
          autofillHints: autofillHints,
          controller: controller,
          cursorColor: AppColors.primary,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon == null
                ? null
                : Icon(
                    icon,
                    color: AppColors.textSubtle,
                    size: AppSizes.iconMedium,
                  ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    required this.controller,
    required this.label,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      autofillHints: const <String>[AutofillHints.password],
      controller: widget.controller,
      icon: AppIcons.lock,
      label: widget.label,
      obscureText: _obscureText,
      suffix: IconButton(
        color: AppColors.textSubtle,
        icon: Icon(
          _obscureText ? AppIcons.visibility : AppIcons.visibilityOff,
          size: AppSizes.iconMedium,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      textInputAction: TextInputAction.done,
    );
  }
}
