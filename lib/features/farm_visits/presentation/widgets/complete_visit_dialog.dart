import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/farm_visit_item.dart';
import '../../domain/services/farm_visit_geo_service.dart';
import 'visit_camera_picker.dart';

class CompleteVisitDialog extends StatefulWidget {
  final FarmVisitItem item;
  final Future<bool> Function({
    required String verifiedAcres,
    required String report,
    String? diagnosis,
    String? recommendation,
  }) onConfirm;
  final Future<String?> Function({
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  })? onUploadPhoto;
  final VisitCameraPicker? cameraPicker;
  final FarmVisitGeoService? geoService;
  final String? Function()? errorMessage;

  const CompleteVisitDialog({
    super.key,
    required this.item,
    required this.onConfirm,
    this.onUploadPhoto,
    this.cameraPicker,
    this.geoService,
    this.errorMessage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required FarmVisitItem item,
    required Future<bool> Function({
      required String verifiedAcres,
      required String report,
      String? diagnosis,
      String? recommendation,
    }) onConfirm,
    Future<String?> Function({
      required List<int> fileBytes,
      required String fileName,
      required String contentType,
    })? onUploadPhoto,
    VisitCameraPicker? cameraPicker,
    FarmVisitGeoService? geoService,
    String? Function()? errorMessage,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => CompleteVisitDialog(
        item: item,
        onConfirm: onConfirm,
        onUploadPhoto: onUploadPhoto,
        cameraPicker: cameraPicker,
        geoService: geoService,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<CompleteVisitDialog> createState() => _CompleteVisitDialogState();
}

class _CompleteVisitDialogState extends State<CompleteVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _acresController = TextEditingController();
  final _reportController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _recommendationController = TextEditingController();

  late final VisitCameraPicker _cameraPicker;
  late final FarmVisitGeoService _geoService;
  VisitPickedPhoto? _capturedPhoto;
  bool _isFetchingGps = false;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoUrl;
  String? _photoError;

  bool _isSubmitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _geoService = widget.geoService ?? const FarmVisitGeoService();
    _cameraPicker = widget.cameraPicker ?? VisitCameraPicker(geoService: _geoService);
    if (widget.item.verifiedAcres != null) {
      _acresController.text = widget.item.verifiedAcres!;
    } else if (widget.item.enrichedCropAcres != null) {
      _acresController.text = widget.item.enrichedCropAcres!;
    }
    if (widget.item.cleanReportNotes != null) {
      _reportController.text = widget.item.cleanReportNotes!;
    } else if (widget.item.report != null) {
      _reportController.text = widget.item.report!;
    }
  }

  @override
  void dispose() {
    _acresController.dispose();
    _reportController.dispose();
    _diagnosisController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      setState(() {
        _photoError = null;
        _isFetchingGps = true;
      });

      // 1. Acquire GPS fix before photo capture
      final gpsResult = await _geoService.getCurrentGpsLocation();
      if (!mounted) return;

      if (gpsResult.error != null) {
        setState(() {
          _photoError = gpsResult.error;
          _isFetchingGps = false;
        });
        return;
      }

      final coords = gpsResult.coords;

      // 2. Trigger Camera with GPS geotagging
      final photo = await _cameraPicker.captureFromCamera(
        gpsCoordinates: coords,
        farmName: widget.item.displayFarmerName,
        farmAddress: widget.item.displayVillage,
      );

      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _capturedPhoto = photo;
          _isFetchingGps = false;
        });
      } else {
        setState(() => _isFetchingGps = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _photoError = 'Could not access camera or GPS. Please check permissions.';
          _isFetchingGps = false;
        });
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      setState(() {
        _photoError = null;
        _isFetchingGps = true;
      });

      final gpsResult = await _geoService.getCurrentGpsLocation();
      if (!mounted) return;

      final coords = gpsResult.coords;

      final photo = await _cameraPicker.pickFromGallery(
        gpsCoordinates: coords,
        farmName: widget.item.displayFarmerName,
        farmAddress: widget.item.displayVillage,
      );

      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _capturedPhoto = photo;
          _isFetchingGps = false;
        });
      } else {
        setState(() => _isFetchingGps = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _photoError = 'Could not pick photo from gallery.';
          _isFetchingGps = false;
        });
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _capturedPhoto = null;
      _uploadedPhotoUrl = null;
      _photoError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    String reportText = _reportController.text.trim();

    // If a photo was captured, upload it and link to visit findings
    if (_capturedPhoto != null && widget.onUploadPhoto != null && _uploadedPhotoUrl == null) {
      try {
        setState(() => _isUploadingPhoto = true);
        final url = await widget.onUploadPhoto!(
          fileBytes: _capturedPhoto!.bytes,
          fileName: _capturedPhoto!.fileName,
          contentType: _capturedPhoto!.mimeType,
        );
        if (url != null && url.isNotEmpty) {
          _uploadedPhotoUrl = url;
          reportText = '$reportText\n[Field Photo]: $url';
        }
      } catch (e) {
        // Log error but proceed if photo is optional
        _photoError = 'Photo upload failed. Proceeding with visit completion notes.';
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    } else if (_uploadedPhotoUrl != null) {
      reportText = '$reportText\n[Field Photo]: $_uploadedPhotoUrl';
    }

    final success = await widget.onConfirm(
      verifiedAcres: _acresController.text.trim(),
      report: reportText,
      diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      recommendation:
          _recommendationController.text.trim().isEmpty ? null : _recommendationController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _localError =
              widget.errorMessage?.call() ?? 'Could not mark visit complete. Please try again.';
        }
      });
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Widget _buildPhotoSection() {
    final photo = _capturedPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Photo (Optional)',
          style: AppTypography.bodySmall(color: AppColors.text)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_isFetchingGps) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.canopy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acquiring GPS fix and verifying location...',
                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ] else if (photo == null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('complete_visit_camera_btn'),
                    onPressed: _isSubmitting || _isUploadingPhoto ? null : _capturePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Capture Field Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.canopy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('complete_visit_gallery_btn'),
                  tooltip: 'Choose from gallery',
                  onPressed: _isSubmitting || _isUploadingPhoto ? null : _pickPhotoFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.textMuted),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            key: const Key('complete_visit_photo_preview'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.canopy.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        Uint8List.fromList(photo.bytes),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photo.fileName,
                            style: AppTypography.bodySmall(color: AppColors.text)
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Size: ${photo.displaySize}',
                            style: AppTypography.caption(color: AppColors.textMuted),
                          ),
                          if (photo.gpsCoordinates != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '📍 ${photo.gpsCoordinates!.formattedLat}, ${photo.gpsCoordinates!.formattedLng}${photo.gpsCoordinates!.formattedAccuracy.isNotEmpty ? ' (${photo.gpsCoordinates!.formattedAccuracy})' : ''}',
                              style: AppTypography.caption(color: AppColors.canopyDeep).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      key: const Key('complete_visit_retake_btn'),
                      onPressed: _isSubmitting || _isUploadingPhoto ? null : _capturePhoto,
                      icon: const Icon(Icons.refresh_rounded, size: 13),
                      label: const Text('Retake'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.canopyDeep,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      key: const Key('complete_visit_remove_photo_btn'),
                      onPressed: _isSubmitting || _isUploadingPhoto ? null : _removePhoto,
                      icon: const Icon(Icons.delete_outline_rounded, size: 13),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.bad,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_photoError != null) ...[
          const SizedBox(height: 4),
          Text(
            _photoError!,
            style: AppTypography.caption(color: AppColors.alert),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Complete Farm Visit',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record field visit findings for ${widget.item.displayFarmerName}:',
                style: AppTypography.bodyMedium(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              // Verified Acres
              TextFormField(
                key: const Key('complete_visit_acres_field'),
                controller: _acresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Verified Acres *',
                  hintText: 'e.g. 2.5',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Acres is required';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Report notes
              TextFormField(
                key: const Key('complete_visit_report_field'),
                controller: _reportController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Visit Report / Notes *',
                  hintText: 'Observations, crop condition...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Report notes required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Diagnosis (optional)
              TextFormField(
                key: const Key('complete_visit_diagnosis_field'),
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis (Optional)',
                  hintText: 'e.g. Healthy vegetative stage',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              // Recommendation (optional)
              TextFormField(
                key: const Key('complete_visit_recommendation_field'),
                controller: _recommendationController,
                decoration: const InputDecoration(
                  labelText: 'Recommendation (Optional)',
                  hintText: 'e.g. Apply organic fertilizer',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              // Field Photo capture section
              _buildPhotoSection(),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('complete_visit_error'),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('complete_visit_submit_btn'),
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.good,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Mark Complete'),
        ),
      ],
    );
  }
}
