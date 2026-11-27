import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for scheduling a farmer grain booking intake slot.
class CreateSlotSheet extends StatefulWidget {
  final String warehouseId;
  final String warehouseName;
  final String? Function()? errorMessage;
  final Future<bool> Function({
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  }) onCreate;

  const CreateSlotSheet({
    super.key,
    required this.warehouseId,
    required this.warehouseName,
    this.errorMessage,
    required this.onCreate,
  });

  @override
  State<CreateSlotSheet> createState() => _CreateSlotSheetState();
}

class _CreateSlotSheetState extends State<CreateSlotSheet> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);
  final _capacityQtlController = TextEditingController(text: '100');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _capacityQtlController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Select slot date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.canopy,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.canopy,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String? _capacityError;
  String? _serverError;

  bool _validate() {
    setState(() {
      _capacityError = null;
      _serverError = null;
      final qtl = double.tryParse(_capacityQtlController.text.trim());
      if (qtl == null || qtl <= 0) {
        _capacityError = 'Enter a valid positive capacity in Quintals.';
      }
      final startMins = _startTime.hour * 60 + _startTime.minute;
      final endMins = _endTime.hour * 60 + _endTime.minute;
      if (endMins <= startMins) {
        _serverError = 'End time must be after start time.';
      }
    });
    return _capacityError == null && _serverError == null;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    final qtl = double.parse(_capacityQtlController.text.trim());
    final capacityKg = qtl * 100.0; // 1 Qtl = 100 Kg

    setState(() {
      _isSubmitting = true;
      _serverError = null;
    });

    final success = await widget.onCreate(
      warehouseId: widget.warehouseId,
      slotDate: _formatDate(_selectedDate),
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      capacityKg: capacityKg,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _serverError = widget.errorMessage?.call() ??
              'Failed to create booking slot. Please try again.';
        }
      });
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              SheetDragHandle(margin: const EdgeInsets.only(bottom: 16)),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open Booking Window',
                          style: AppTypography.titleMedium(
                            color: AppColors.text,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Facility: ${widget.warehouseName}',
                          style: AppTypography.caption(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Date Picker Field
              Text(
                'Slot Date *',
                style: AppTypography.caption(color: AppColors.text).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.canopy),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Time Window Pickers (Start - End)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time *',
                          style: AppTypography.caption(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppColors.radiusSm),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _startTime.format(context),
                                    style: AppTypography.bodySmall(color: AppColors.text),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                          ),
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
                          'End Time *',
                          style: AppTypography.caption(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickEndTime,
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppColors.radiusSm),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _endTime.format(context),
                                    style: AppTypography.bodySmall(color: AppColors.text),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Slot Intake Capacity in Quintals
              AppTextField(
                label: 'Slot Intake Capacity (Quintals) *',
                hint: 'e.g. 100 (equivalent to 10,000 kg)',
                controller: _capacityQtlController,
                errorText: _capacityError,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isSubmitting,
              ),

              if (_serverError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.badBg,
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    border: Border.all(color: AppColors.bad.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.bad),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: AppTypography.caption(color: AppColors.bad),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        ),
                        side: const BorderSide(color: AppColors.line),
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTypography.bodySmall(color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.canopy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create Slot',
                              style: AppTypography.bodySmall(color: Colors.white).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}
