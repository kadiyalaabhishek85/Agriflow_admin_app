import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for logging received crop procurement.
class LogReceivedCropSheet extends StatefulWidget {
  final Map<String, ({String name, String phone, String? village})> farmers;
  final bool isSubmitting;
  final String? Function()? errorMessage;
  final Future<bool> Function({
    required String farmerId,
    required String grainType,
    required String grade,
    required double rawMaterialKg,
    required double goodMaterialKg,
    required double wastageKg,
  }) onSubmit;

  const LogReceivedCropSheet({
    super.key,
    required this.farmers,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Map<String, ({String name, String phone, String? village})> farmers,
    required bool isSubmitting,
    String? Function()? errorMessage,
    required Future<bool> Function({
      required String farmerId,
      required String grainType,
      required String grade,
      required double rawMaterialKg,
      required double goodMaterialKg,
      required double wastageKg,
    }) onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LogReceivedCropSheet(
        farmers: farmers,
        isSubmitting: isSubmitting,
        errorMessage: errorMessage,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<LogReceivedCropSheet> createState() => _LogReceivedCropSheetState();
}

class _LogReceivedCropSheetState extends State<LogReceivedCropSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFarmerId;
  String _selectedGrainType = 'Rice';
  String _selectedGrade = 'A';
  bool _submitting = false;
  String? _localError;

  final _rawController = TextEditingController();
  final _goodController = TextEditingController();
  final _wastageController = TextEditingController();

  final List<String> _grainTypes = const [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Groundnut',
    'Sugarcane',
  ];

  final List<String> _grades = const ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    if (widget.farmers.isNotEmpty) {
      _selectedFarmerId = widget.farmers.keys.first;
    }
  }

  @override
  void dispose() {
    _rawController.dispose();
    _goodController.dispose();
    _wastageController.dispose();
    super.dispose();
  }

  void _onRawOrGoodChanged() {
    final raw = double.tryParse(_rawController.text.trim()) ?? 0.0;
    final good = double.tryParse(_goodController.text.trim()) ?? 0.0;
    if (raw > 0 && good >= 0 && raw >= good) {
      final wastage = raw - good;
      _wastageController.text = wastage.toStringAsFixed(1);
    }
    setState(() {});
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarmerId == null || _selectedFarmerId!.isEmpty) {
      setState(() => _localError = 'Please select a farmer.');
      return;
    }

    final rawQtl = double.tryParse(_rawController.text.trim()) ?? 0.0;
    final goodQtl = double.tryParse(_goodController.text.trim()) ?? 0.0;
    final wastageQtl = double.tryParse(_wastageController.text.trim()) ?? 0.0;

    if ((goodQtl + wastageQtl - rawQtl).abs() > 0.01) {
      setState(() {
        _localError =
            'Good Quantity (${goodQtl.toStringAsFixed(1)}) + Wastage (${wastageQtl.toStringAsFixed(1)}) must equal Raw Quantity (${rawQtl.toStringAsFixed(1)}).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });

    // Convert Quintals to Kilograms for backend (1 Qtl = 100 Kg)
    final success = await widget.onSubmit(
      farmerId: _selectedFarmerId!,
      grainType: _selectedGrainType,
      grade: _selectedGrade,
      rawMaterialKg: rawQtl * 100.0,
      goodMaterialKg: goodQtl * 100.0,
      wastageKg: wastageQtl * 100.0,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _localError = widget.errorMessage?.call() ??
            'Failed to save procurement entry. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW PROCUREMENT INTAKE',
                          style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Log Received Crop',
                          style: AppTypography.titleLarge(color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Farmer Selection
              Text(
                'Farmer *',
                style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.farmers.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedFarmerId,
                  isExpanded: true,
                  decoration: InputDecoration(
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
                  ),
                  items: widget.farmers.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        '${entry.value.name} (${entry.value.phone})',
                        style: AppTypography.bodySmall(color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFarmerId = val);
                  },
                )
              else
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter farmer ID',
                    fillColor: AppColors.surfaceAlt,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                  onChanged: (val) => _selectedFarmerId = val.trim(),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Farmer ID required' : null,
                ),

              const SizedBox(height: 14),

              // Crop Type & Grade Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crop Type *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGrainType,
                          decoration: InputDecoration(
                            fillColor: AppColors.surfaceAlt,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                          items: _grainTypes.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGrainType = val);
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
                          'Grade *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGrade,
                          decoration: InputDecoration(
                            fillColor: AppColors.surfaceAlt,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                          items: _grades.map((g) {
                            return DropdownMenuItem(value: g, child: Text('Grade $g'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGrade = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quantities Row (Raw, Good, Wastage) in Quintals
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raw Quantity (Quintals) *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rawController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'e.g. 10.0',
                            fillColor: AppColors.surfaceAlt,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                          onChanged: (_) => _onRawOrGoodChanged(),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final n = double.tryParse(val.trim());
                            if (n == null || n <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Quantity (Quintals) *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _goodController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'e.g. 9.5',
                            fillColor: AppColors.surfaceAlt,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                          onChanged: (_) => _onRawOrGoodChanged(),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wastage (Quintals) *',
                          style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _wastageController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'e.g. 0.5',
                            fillColor: AppColors.surfaceAlt,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_localError != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('log_crop_error_banner'),
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
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: (widget.isSubmitting || _submitting) ? null : _handleSubmit,
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
                child: (widget.isSubmitting || _submitting)
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
                          const Icon(Icons.add_task_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Save Procurement Entry',
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
