import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/farmer_item.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Bottom sheet displaying farmer profile and operational actions.
/// Matches the approved `#overlay-farmer-view` HTML component.
class FarmerDetailSheet extends StatelessWidget {
  final FarmerItem farmer;
  final bool isAdmin;
  final bool isSubmitting;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onSuspend;
  final VoidCallback? onEdit;
  final void Function(String phone)? onCallFarmer;

  const FarmerDetailSheet({
    super.key,
    required this.farmer,
    required this.isAdmin,
    this.isSubmitting = false,
    this.onApprove,
    this.onReject,
    this.onSuspend,
    this.onEdit,
    this.onCallFarmer,
  });

  Future<void> _handlePhoneTap(BuildContext context) async {
    final rawPhone = farmer.phone.trim();
    if (rawPhone.isEmpty) return;

    if (onCallFarmer != null) {
      onCallFarmer!(rawPhone);
      return;
    }

    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer.'),
            backgroundColor: AppColors.text,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                SheetDragHandle(margin: const EdgeInsets.only(bottom: 12)),

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FARMER PROFILE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textFaint,
                      ),
                    ),
                    SquircleIconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      size: 32,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Centered Avatar & Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F6EA),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColors.canopyLight.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          farmer.initials,
                          style: const TextStyle(
                            color: AppColors.canopyDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        farmer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      StatusPill.fromStatus(farmer.status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2x2 Grid of cards
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        label: 'PHONE',
                        value: farmer.phone,
                        icon: Icons.phone_outlined,
                        onTap: farmer.phone.trim().isNotEmpty
                            ? () => _handlePhoneTap(context)
                            : null,
                        actionIcon: farmer.phone.trim().isNotEmpty
                            ? Icons.open_in_new_rounded
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDetailCard(
                        label: 'LAND SIZE',
                        value: farmer.landAcresDisplay,
                        icon: Icons.landscape_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        label: 'EMAIL',
                        value: farmer.email?.isNotEmpty == true
                            ? farmer.email!
                            : 'Not provided',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDetailCard(
                        label: 'JOINED',
                        value: farmer.formattedJoinedDate,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),

                if (farmer.villageOrAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailCard(
                    label: 'VILLAGE / ADDRESS',
                    value: farmer.villageOrAddress,
                    icon: Icons.location_on_outlined,
                  ),
                ],

                const SizedBox(height: 16),

                // Call Farmer Button
                ElevatedButton.icon(
                  key: const Key('farmer_call_btn'),
                  onPressed: farmer.phone.trim().isNotEmpty
                      ? () => _handlePhoneTap(context)
                      : null,
                  icon: const Icon(Icons.phone_forwarded_rounded, size: 18),
                  label: Text(
                    'Call ${farmer.name.split(' ').first} (${farmer.phone})',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.canopy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.line,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),

                // Admin profile edit (FEAT-04)
                if (isAdmin && onEdit != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('farmer_edit_profile_btn'),
                    onPressed: isSubmitting ? null : onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.canopy,
                    ),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(color: AppColors.canopy),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                // Status Actions
                if (farmer.isPending &&
                    onApprove != null &&
                    onReject != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSubmitting ? null : onReject,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.bad,
                          ),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: AppColors.bad),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.badBg),
                            backgroundColor: AppColors.badBg.withValues(
                              alpha: 0.3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : onApprove,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.good,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Admin Suspend Action
                if (isAdmin && farmer.isActive && onSuspend != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isSubmitting ? null : onSuspend,
                    icon: const Icon(
                      Icons.block_outlined,
                      size: 16,
                      color: AppColors.warn,
                    ),
                    label: const Text(
                      'Suspend Farmer Account',
                      style: TextStyle(color: AppColors.warn),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.warnBg),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onTap != null ? AppColors.canopy.withValues(alpha: 0.3) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: onTap != null ? AppColors.canopyDeep : AppColors.textFaint),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: onTap != null ? AppColors.canopyDeep : AppColors.textFaint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (actionIcon != null)
                Icon(actionIcon, size: 12, color: AppColors.canopyDeep),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: onTap != null ? AppColors.canopyDeep : AppColors.text,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
