import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/squircle_icon_button.dart';

/// Help & Support screen (M10, AdminMobile UIUX `#screen-help`).
class HelpScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const HelpScreen({super.key, this.onBack});

  static const String supportPhone = '+91 9502662924';

  static const List<String> faqQuestions = [
    'How do I approve a seed request?',
    'How do I create a new visit slot?',
    'How do I mark a grain sale as paid?',
  ];

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SquircleIconButton.back(onTap: () => _back(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Help & Support',
                    style: AppTypography.titleLarge(
                      color: AppColors.adminNavyDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Support',
                    style: AppTypography.titleSmall(color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Call us at $supportPhone for any assistance.',
                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently asked',
                    style: AppTypography.titleSmall(color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  for (final q in faqQuestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '→  $q',
                        style: AppTypography.bodySmall(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
