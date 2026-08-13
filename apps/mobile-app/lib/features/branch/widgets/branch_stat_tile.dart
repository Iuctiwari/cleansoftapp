import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// Small colored metric tile used in the Branch List and Branch Details
/// summary rows (e.g. "Total Staff", "Orders Today").
///
/// Some values (staff/orders) are not yet backed by an API — callers pass
/// `0` for those until Staff/Order Management ships. The widget itself has
/// no knowledge of which values are real vs. placeholder.
class BranchStatTile extends StatelessWidget {
  const BranchStatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });

  final Color background;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.headingLarge.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of evenly spaced [BranchStatTile]s, e.g. the 3-tile summary strip on
/// the Branch List and Branch Details screens.
class BranchStatRow extends StatelessWidget {
  const BranchStatRow({required this.tiles, super.key});

  final List<BranchStatTile> tiles;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AppSpacing.md));
      children.add(Expanded(child: tiles[i]));
    }
    return Row(children: children);
  }
}
