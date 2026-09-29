import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../data/notification_preferences.dart';

/// Settings & preferences screen (M10, AdminMobile UIUX `#screen-settings`).
///
/// Notification toggles are device-local ([NotificationPreferences]); the
/// Terms of Service and Privacy Policy rows push static legal documents.
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool>? _values;

  @override
  void initState() {
    super.initState();
    NotificationPreferences.load().then((loaded) {
      if (!mounted) return;
      setState(() => _values = loaded);
    });
  }

  void _onToggle(String key, bool value) {
    setState(() => _values = {...?_values, key: value});
    NotificationPreferences.save(key, value);
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(title: title, body: body),
      ),
    );
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SquircleIconButton.back(onTap: _back),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Settings',
                    style: AppTypography.titleLarge(
                      color: AppColors.adminNavyDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (values == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  children: [
                    _ToggleRow(
                      label: 'Push notifications',
                      value: values[NotificationPreferences.pushKey]!,
                      onChanged: (v) =>
                          _onToggle(NotificationPreferences.pushKey, v),
                    ),
                    const Divider(
                      height: 1,
                      color: AppColors.line,
                      indent: 14,
                      endIndent: 14,
                    ),
                    _ToggleRow(
                      label: 'Email alerts',
                      value: values[NotificationPreferences.emailKey]!,
                      onChanged: (v) =>
                          _onToggle(NotificationPreferences.emailKey, v),
                    ),
                    const Divider(
                      height: 1,
                      color: AppColors.line,
                      indent: 14,
                      endIndent: 14,
                    ),
                    _ToggleRow(
                      label: 'SMS alerts for urgent items',
                      value: values[NotificationPreferences.smsKey]!,
                      onChanged: (v) =>
                          _onToggle(NotificationPreferences.smsKey, v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _LegalRow(
                label: 'Terms of service',
                onTap: () => _openLegal(
                  'Terms of Service',
                  'This Admin console is for authorized personnel of Sri Siva Sai Seeds '
                      'only. All actions taken (approvals, payments, bookings) are logged '
                      'and auditable.',
                ),
              ),
              const SizedBox(height: 12),
              _LegalRow(
                label: 'Privacy policy',
                onTap: () => _openLegal(
                  'Privacy Policy',
                  'Farmer and transaction data accessed through this console is '
                      'confidential and must not be shared outside authorized business use.',
                ),
              ),
            ],

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Sri Siva Sai Seeds Admin Console v1.0.0',
                style: AppTypography.bodySmall(color: AppColors.textFaint),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleSmall(color: AppColors.text),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.canopy,
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _LegalRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleSmall(color: AppColors.text),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textFaint,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Static legal document screen (Terms of Service / Privacy Policy) with
/// verbatim copy from the approved HTML design.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

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
                SquircleIconButton.back(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
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
              child: Text(
                body,
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
