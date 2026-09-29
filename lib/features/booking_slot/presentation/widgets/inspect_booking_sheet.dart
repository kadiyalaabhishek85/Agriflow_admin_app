import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for recording crop inspection on a delivered booking
/// via POST /api/v1/bookings/{booking_id}/inspect.
class InspectBookingSheet extends StatefulWidget {
  final bool isSubmitting;
  final Future<bool> Function({
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  }) onSubmit;
  final String? Function()? errorMessage;

  const InspectBookingSheet({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  static Future<bool?> show({
    required BuildContext context,
    required bool isSubmitting,
    required Future<bool> Function({
      required double goodQuantityKg,
      required double badQuantityKg,
      String? rejectionReason,
      String? notes,
    }) onSubmit,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InspectBookingSheet(
        isSubmitting: isSubmitting,
        onSubmit: onSubmit,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<InspectBookingSheet> createState() => _InspectBookingSheetState();
}

class _InspectBookingSheetState extends State<InspectBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _goodController = TextEditingController();
  final _badController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _localError;

  @override
  void dispose() {
    _goodController.dispose();
    _badController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final good = double.tryParse(_goodController.text.trim()) ?? -1;
    final bad = double.tryParse(_badController.text.trim()) ?? -1;
    if (good < 0 || bad < 0) {
      setState(() => _localError = 'Quantities must be zero or greater.');
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });
    final success = await widget.onSubmit(
      goodQuantityKg: good,
      badQuantityKg: bad,
      rejectionReason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _localError = widget.errorMessage?.call() ?? 'Could not record inspection.';
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      fillColor: AppColors.surfaceAlt,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall(color: AppColors.text).copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || widget.isSubmitting;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetDragHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CROP INSPECTION',
                        style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Record Inspection',
                        style: AppTypography.titleLarge(color: AppColors.text),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Good Quantity (kg) *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _goodController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoration('e.g. 950.0'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final n = double.tryParse(val.trim());
                            if (n == null || n < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Bad Quantity (kg) *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _badController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoration('e.g. 50.0'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final n = double.tryParse(val.trim());
                            if (n == null || n < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('Rejection Reason'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                decoration: _decoration('Optional — if quality is rejected'),
              ),
              const SizedBox(height: 14),
              _label('Notes'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _decoration('Optional observations'),
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('inspect_booking_error'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _localError!,
                    style: AppTypography.bodySmall(color: AppColors.alert),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('inspect_booking_submit_btn'),
                onPressed: busy ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopyDeep,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.canopyDeep.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fact_check_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Submit Inspection',
                            style: AppTypography.titleSmall(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
