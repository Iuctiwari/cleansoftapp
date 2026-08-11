import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A selectable chip for the Business Type grid.
///
/// Shows a bordered chip; when [isSelected] the border and text turn
/// primary blue to match the design in the screenshots.
class BusinessTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BusinessTypeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryLight : kSurface,
          border: Border.all(
            color: isSelected ? kChipSelected : kBorder,
            width: isSelected ? 1.8 : 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? kChipSelected : kTextPrimary,
          ),
        ),
      ),
    );
  }
}
