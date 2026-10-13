import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// The photos the worker took when collecting the order. Tap one to see it full screen.
class PickupPhotos extends StatelessWidget {
  const PickupPhotos({required this.urls, super.key});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.pickupPhotosTitle, style: AppTextStyles.labelBold),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) => GestureDetector(
              key: Key('pickup.photo.$index'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext dialogContext) => Dialog(
                  insetPadding: const EdgeInsets.all(AppSpacing.md),
                  child: InteractiveViewer(child: Image.network(urls[index], fit: BoxFit.contain)),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urls[index],
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 88, height: 88, child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
