import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../domain/entities/farm_visit_item.dart';

class RescheduleVisitDialog extends StatefulWidget {
  final FarmVisitItem item;
  final Future<bool> Function(String scheduledDate) onConfirm;
  final String? Function()? errorMessage;

  const RescheduleVisitDialog({
    super.key,
    required this.item,
    required this.onConfirm,
    this.errorMessage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required FarmVisitItem item,
    required Future<bool> Function(String scheduledDate) onConfirm,
    String? Function()? errorMessage,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RescheduleVisitDialog(
        item: item,
        onConfirm: onConfirm,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<RescheduleVisitDialog> createState() => _RescheduleVisitDialogState();
}

class _RescheduleVisitDialogState extends State<RescheduleVisitDialog> {
  late DateTime _selectedDate;
  bool _isSubmitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    if (widget.item.scheduledDate != null) {
      _selectedDate = DateTime.tryParse(widget.item.scheduledDate!) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select new visit date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _localError = null;
    });
    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final success = await widget.onConfirm(dateStr);
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _localError =
              widget.errorMessage?.call() ?? 'Could not reschedule visit. Please try again.';
        }
      });
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text(
        'Reschedule Visit',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select new scheduled visit date for ${widget.item.displayFarmerName}:',
            style: AppTypography.bodyMedium(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _isSubmitting ? null : _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceAlt,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.calendar_month, color: AppColors.canopy, size: 20),
                ],
              ),
            ),
          ),
          if (_localError != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('reschedule_visit_error'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.alert.withValues(alpha: 0.4)),
              ),
              child: Text(
                _localError!,
                style: AppTypography.bodySmall(color: AppColors.alert),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.canopy,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Date'),
        ),
      ],
    );
  }
}
