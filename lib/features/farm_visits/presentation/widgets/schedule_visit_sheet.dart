import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for creating a farm visit via POST /api/v1/farm-visits.
/// Fields: crop (required), visit month 1-6 (required), scheduled date
/// (required), staff assignment (optional).
class ScheduleVisitSheet extends StatefulWidget {
  final Future<Map<String, ({String cropType, String acres})>> Function() loadCrops;
  final Future<Map<String, ({String name, String phone})>> Function() loadStaff;
  final Future<bool> Function({
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) onSubmit;
  final bool isSubmitting;
  final String? Function()? errorMessage;

  const ScheduleVisitSheet({
    super.key,
    required this.loadCrops,
    required this.loadStaff,
    required this.onSubmit,
    required this.isSubmitting,
    this.errorMessage,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Future<Map<String, ({String cropType, String acres})>> Function() loadCrops,
    required Future<Map<String, ({String name, String phone})>> Function() loadStaff,
    required Future<bool> Function({
      required String cropId,
      required int visitMonth,
      required String scheduledDate,
      String? staffId,
    }) onSubmit,
    required bool isSubmitting,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleVisitSheet(
        loadCrops: loadCrops,
        loadStaff: loadStaff,
        onSubmit: onSubmit,
        isSubmitting: isSubmitting,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends State<ScheduleVisitSheet> {
  Map<String, ({String cropType, String acres})>? _crops;
  Map<String, ({String name, String phone})>? _staff;
  bool _loadingLookups = true;

  String? _cropId;
  int? _month;
  DateTime? _date;
  String? _staffId;

  bool _submitting = false;
  String? _localError;
  final _dateFieldKey = GlobalKey<FormFieldState<DateTime>>();

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _localError = null;
    });
    try {
      final crops = await widget.loadCrops();
      final staff = await widget.loadStaff();
      if (!mounted) return;
      setState(() {
        _crops = crops;
        _staff = staff;
        _loadingLookups = false;
        if (crops.isEmpty) {
          _localError = 'No crops available. Add a crop before scheduling a visit.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLookups = false;
        _localError = 'Could not load form options. Close and try again.';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select visit date',
    );
    if (picked != null) {
      setState(() => _date = picked);
      _dateFieldKey.currentState?.didChange(picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cropId == null || _month == null || _date == null) return;

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final dateStr =
        '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
    final success = await widget.onSubmit(
      cropId: _cropId!,
      visitMonth: _month!,
      scheduledDate: dateStr,
      staffId: _staffId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _localError = widget.errorMessage?.call() ?? 'Could not schedule the visit. Please try again.';
    });
  }

  final _formKey = GlobalKey<FormState>();

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

  String _dateLabel() {
    if (_date == null) return 'Select date';
    return '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || widget.isSubmitting;
    final crops = _crops;
    final staff = _staff;
    final noCrops = !_loadingLookups && (crops?.isEmpty ?? false);

    return Container(
      key: const Key('schedule_visit_sheet'),
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
                        'FARM VISITS',
                        style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Schedule a Visit',
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
              if (_loadingLookups)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Text(
                  'Crop *',
                  style: AppTypography.bodySmall(color: AppColors.text)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: const Key('schedule_visit_crop_field'),
                  initialValue: _cropId,
                  hint: Text('Select crop', style: AppTypography.bodyMedium(color: AppColors.textFaint)),
                  isExpanded: true,
                  decoration: _decoration('Select crop'),
                  items: (crops?.entries ?? const [])
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            e.value.acres.isEmpty
                                ? e.value.cropType
                                : '${e.value.cropType} (${e.value.acres} ac)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => _cropId = v),
                  validator: (v) => v == null || v.isEmpty ? 'Please select a crop' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visit Month (1-6) *',
                            style: AppTypography.bodySmall(color: AppColors.text)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            key: const Key('schedule_visit_month_field'),
                            initialValue: _month,
                            hint: Text('Month', style: AppTypography.bodyMedium(color: AppColors.textFaint)),
                            decoration: _decoration('Month'),
                            items: List.generate(
                              6,
                              (i) => DropdownMenuItem<int>(
                                value: i + 1,
                                child: Text('${i + 1}'),
                              ),
                            ),
                            onChanged: busy ? null : (v) => setState(() => _month = v),
                            validator: (v) => v == null ? 'Required' : null,
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
                            'Scheduled Date *',
                            style: AppTypography.bodySmall(color: AppColors.text)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          FormField<DateTime>(
                            key: _dateFieldKey,
                            validator: (v) => v == null ? 'Date is required' : null,
                            builder: (state) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  key: const Key('schedule_visit_date_field'),
                                  onTap: busy ? null : _pickDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: state.hasError ? AppColors.alert : AppColors.line,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _dateLabel(),
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodyMedium(
                                              color:
                                                  _date == null ? AppColors.textFaint : AppColors.text,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.calendar_month,
                                            color: AppColors.canopy, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 4),
                                    child: Text(
                                      state.errorText!,
                                      style:
                                          AppTypography.bodySmall(color: AppColors.alert),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Assign Staff (optional)',
                  style: AppTypography.bodySmall(color: AppColors.text)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  key: const Key('schedule_visit_staff_field'),
                  initialValue: _staffId,
                  hint: Text('Unassigned', style: AppTypography.bodyMedium(color: AppColors.textFaint)),
                  isExpanded: true,
                  decoration: _decoration('Unassigned'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...(staff?.entries ?? const [])
                        .map(
                          (e) => DropdownMenuItem<String?>(
                            value: e.key,
                            child: Text(
                              '${e.value.name} (${e.value.phone})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: busy ? null : (v) => setState(() => _staffId = v),
                ),
              ],
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('schedule_visit_error'),
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
                key: const Key('schedule_visit_submit_btn'),
                onPressed: busy || _loadingLookups || noCrops ? null : _handleSubmit,
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
                          const Icon(Icons.event_available_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Schedule Visit',
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
