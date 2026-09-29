import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for correcting grain-sale yield quantities (kg)
/// via PATCH /api/v1/grain-sales/{sale_id}/yield.
class UpdateYieldSheet extends StatefulWidget {
  final String goodMaterialKg;
  final String wastageKg;
  final bool isSubmitting;
  final Future<bool> Function({
    required double goodMaterialKg,
    required double wastageKg,
  }) onSubmit;
  final String? Function()? errorMessage;

  const UpdateYieldSheet({
    super.key,
    required this.goodMaterialKg,
    required this.wastageKg,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String goodMaterialKg,
    required String wastageKg,
    required bool isSubmitting,
    required Future<bool> Function({
      required double goodMaterialKg,
      required double wastageKg,
    }) onSubmit,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateYieldSheet(
        goodMaterialKg: goodMaterialKg,
        wastageKg: wastageKg,
        isSubmitting: isSubmitting,
        onSubmit: onSubmit,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<UpdateYieldSheet> createState() => _UpdateYieldSheetState();
}

class _UpdateYieldSheetState extends State<UpdateYieldSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _goodController;
  late final TextEditingController _wastageController;
  bool _submitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _goodController = TextEditingController(text: widget.goodMaterialKg);
    _wastageController = TextEditingController(text: widget.wastageKg);
  }

  @override
  void dispose() {
    _goodController.dispose();
    _wastageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final good = double.tryParse(_goodController.text.trim()) ?? -1;
    final wastage = double.tryParse(_wastageController.text.trim()) ?? -1;
    if (good < 0 || wastage < 0) {
      setState(() => _localError = 'Quantities must be zero or greater.');
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });
    final success = await widget.onSubmit(
      goodMaterialKg: good,
      wastageKg: wastage,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _localError = widget.errorMessage?.call() ?? 'Could not update yield. Please try again.';
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
                        'YIELD CORRECTION',
                        style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Update Yield Quantities',
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
                        Text(
                          'Good Material (kg) *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        Text(
                          'Wastage (kg) *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _wastageController,
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
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('update_yield_error'),
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
                key: const Key('update_yield_submit_btn'),
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
                          const Icon(Icons.scale_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Save Yield',
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
