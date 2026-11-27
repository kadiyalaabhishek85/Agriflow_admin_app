import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/error_sanitizer.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../domain/entities/seed_inventory_item.dart';
import '../../domain/entities/seed_warehouse_brief.dart';
import '../../domain/exceptions/seeds_inventory_exception.dart';
import 'seed_image_picker.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Bottom sheet modal for adding or editing a seed product in the catalog.
/// Implements live FastAPI OpenAPI schemas including Grade A/B/C pricing,
/// multi-warehouse assignment checkboxes, max order quantity, and seed image upload.
class AddEditSeedSheet extends StatefulWidget {
  final SeedInventoryItem? seed;
  final List<SeedWarehouseBrief> availableWarehouses;
  final Future<bool> Function({
    required String name,
    required double pricePerKg,
    required double stockKg,
    String? cropType,
    String? variety,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    List<String>? warehouseIds,
    String? description,
    String? imageUrl,
  }) onAdd;

  final Future<bool> Function({
    required String seedId,
    String? name,
    String? cropType,
    String? variety,
    double? pricePerKg,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    double? stockKg,
    List<String>? warehouseIds,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) onEdit;

  final Future<String?> Function({
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  })? onUploadImage;

  /// Injectable image picker; defaults to the device gallery picker.
  final SeedImagePicker? imagePicker;

  /// Optional provider returning the latest controller error when [onAdd] / [onEdit] returns false.
  final String? Function()? errorProvider;

  const AddEditSeedSheet({
    super.key,
    this.seed,
    this.availableWarehouses = const [],
    required this.onAdd,
    required this.onEdit,
    this.onUploadImage,
    this.imagePicker,
    this.errorProvider,
  });

  @override
  State<AddEditSeedSheet> createState() => _AddEditSeedSheetState();
}

class _AddEditSeedSheetState extends State<AddEditSeedSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _cropTypeController;
  late final TextEditingController _varietyController;
  late final TextEditingController _priceController;
  late final TextEditingController _priceGradeAController;
  late final TextEditingController _priceGradeBController;
  late final TextEditingController _priceGradeCController;
  late final TextEditingController _maxOrderController;
  late final TextEditingController _stockQtlController;
  late final TextEditingController _descController;
  late final TextEditingController _imageUrlController;

  String? _nameError;
  String? _priceError;
  String? _stockError;
  String? _gradeAError;
  String? _gradeBError;
  String? _gradeCError;
  String? _maxOrderError;
  String? _submitError;
  String? _uploadError;

  late bool _isActive;
  late List<String> _selectedWarehouseIds;
  bool _isSubmitting = false;
  bool _isUploading = false;
  bool _showImageInput = false;
  late final SeedImagePicker _imagePicker;

  bool get isEditing => widget.seed != null;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? SeedImagePicker();
    final seed = widget.seed;
    _nameController = TextEditingController(text: seed?.name ?? '');
    _cropTypeController = TextEditingController(text: seed?.cropType ?? '');
    _varietyController = TextEditingController(text: seed?.variety ?? '');
    _priceController = TextEditingController(
      text: seed != null ? seed.displayPrice : '',
    );
    _priceGradeAController = TextEditingController(
      text: seed?.displayPriceGradeA ?? '',
    );
    _priceGradeBController = TextEditingController(
      text: seed?.displayPriceGradeB ?? '',
    );
    _priceGradeCController = TextEditingController(
      text: seed?.displayPriceGradeC ?? '',
    );
    _maxOrderController = TextEditingController(
      text: seed?.displayMaxOrderQuantity ?? '',
    );
    // User enters stock in Quintals (1 Qtl = 100 Kg)
    _stockQtlController = TextEditingController(
      text: seed != null ? seed.displayStockQtl : '',
    );
    _descController = TextEditingController(text: seed?.description ?? '');
    _imageUrlController = TextEditingController(text: seed?.imageUrl ?? '');
    _isActive = seed?.isActive ?? true;

    // Initialize selected warehouse IDs from seed or fallback to warehouseId
    _selectedWarehouseIds = List<String>.from(
      seed?.warehouseIds ?? (seed?.warehouseId != null ? [seed!.warehouseId!] : <String>[]),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cropTypeController.dispose();
    _varietyController.dispose();
    _priceController.dispose();
    _priceGradeAController.dispose();
    _priceGradeBController.dispose();
    _priceGradeCController.dispose();
    _maxOrderController.dispose();
    _stockQtlController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _priceError = null;
      _stockError = null;
      _gradeAError = null;
      _gradeBError = null;
      _gradeCError = null;
      _maxOrderError = null;
      _submitError = null;

      final name = _nameController.text.trim();
      if (name.length < 2) {
        _nameError = 'Seed name must be at least 2 characters';
        valid = false;
      } else if (name.length > 120) {
        _nameError = 'Seed name must be under 120 characters';
        valid = false;
      }

      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);
      if (priceText.isEmpty || price == null || price <= 0) {
        _priceError = 'Base price must be greater than 0';
        valid = false;
      }

      final stockText = _stockQtlController.text.trim();
      final stock = double.tryParse(stockText);
      if (stockText.isEmpty || stock == null || stock < 0) {
        _stockError = 'Stock must be 0 or greater';
        valid = false;
      }

      final gradeAText = _priceGradeAController.text.trim();
      if (gradeAText.isNotEmpty) {
        final val = double.tryParse(gradeAText);
        if (val == null || val <= 0) {
          _gradeAError = 'Must be > 0';
          valid = false;
        }
      }

      final gradeBText = _priceGradeBController.text.trim();
      if (gradeBText.isNotEmpty) {
        final val = double.tryParse(gradeBText);
        if (val == null || val <= 0) {
          _gradeBError = 'Must be > 0';
          valid = false;
        }
      }

      final gradeCText = _priceGradeCController.text.trim();
      if (gradeCText.isNotEmpty) {
        final val = double.tryParse(gradeCText);
        if (val == null || val <= 0) {
          _gradeCError = 'Must be > 0';
          valid = false;
        }
      }

      final maxOrderText = _maxOrderController.text.trim();
      if (maxOrderText.isNotEmpty) {
        final val = double.tryParse(maxOrderText);
        if (val == null || val <= 0) {
          _maxOrderError = 'Must be > 0';
          valid = false;
        }
      }
    });

    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    final price = double.parse(_priceController.text.trim());
    final stockQtl = double.parse(_stockQtlController.text.trim());
    final stockKg = stockQtl * 100.0;

    final priceGradeA = _priceGradeAController.text.trim().isNotEmpty
        ? double.tryParse(_priceGradeAController.text.trim())
        : null;
    final priceGradeB = _priceGradeBController.text.trim().isNotEmpty
        ? double.tryParse(_priceGradeBController.text.trim())
        : null;
    final priceGradeC = _priceGradeCController.text.trim().isNotEmpty
        ? double.tryParse(_priceGradeCController.text.trim())
        : null;
    final maxOrder = _maxOrderController.text.trim().isNotEmpty
        ? double.tryParse(_maxOrderController.text.trim())
        : null;

    final name = _nameController.text.trim();
    final cropType = _cropTypeController.text.trim().isNotEmpty
        ? _cropTypeController.text.trim()
        : null;
    final variety = _varietyController.text.trim().isNotEmpty
        ? _varietyController.text.trim()
        : null;
    final desc = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : null;
    final imageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : null;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    bool success;
    if (isEditing) {
      success = await widget.onEdit(
        seedId: widget.seed!.id,
        name: name,
        cropType: cropType,
        variety: variety,
        pricePerKg: price,
        priceGradeA: priceGradeA,
        priceGradeB: priceGradeB,
        priceGradeC: priceGradeC,
        maxOrderQuantityKg: maxOrder,
        stockKg: stockKg,
        warehouseIds: _selectedWarehouseIds,
        description: desc,
        imageUrl: imageUrl,
        isActive: _isActive,
      );
    } else {
      success = await widget.onAdd(
        name: name,
        cropType: cropType,
        variety: variety,
        pricePerKg: price,
        priceGradeA: priceGradeA,
        priceGradeB: priceGradeB,
        priceGradeC: priceGradeC,
        maxOrderQuantityKg: maxOrder,
        stockKg: stockKg,
        warehouseIds: _selectedWarehouseIds,
        description: desc,
        imageUrl: imageUrl,
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _submitError = widget.errorProvider?.call() ??
              'Unable to save seed changes. Please try again.';
        }
      });
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleImageUpload() async {
    if (widget.onUploadImage == null) return;
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final picked = await _imagePicker.pickImage();
      // User cancelled the gallery — return to idle without an error.
      if (picked == null) return;

      final url = await widget.onUploadImage!(
        fileBytes: picked.bytes,
        fileName: picked.fileName,
        contentType: picked.mimeType,
      );

      if (mounted) {
        if (url != null && url.isNotEmpty) {
          setState(() {
            _imageUrlController.text = url;
            _showImageInput = false;
          });
        } else {
          setState(() =>
              _uploadError = 'Image upload completed, but the server did not return a public image URL.');
        }
      }
    } on SeedsInventoryException catch (e) {
      if (mounted) setState(() => _uploadError = e.message);
    } catch (_) {
      // Never display raw exception text — fixed safe message only.
      if (mounted) setState(() => _uploadError = ErrorSanitizer.genericErrorMessage);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              SheetDragHandle(),
              const SizedBox(height: 14),

              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seed catalogue',
                          style: AppTypography.eyebrow(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing ? 'Edit Seed Product' : 'Add New Seed Variety',
                          style: AppTypography.titleLarge(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SquircleIconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            if (_submitError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.badLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.bad.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _submitError!,
                  style: AppTypography.bodySmall(color: AppColors.bad),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 1. Seed Image Section
            _buildImageSection(),
            const SizedBox(height: 16),

            // 2. Seed Name
            AppTextField(
              label: 'Seed Name *',
              controller: _nameController,
              hint: 'e.g. BPT-5204 (Samba Mahsuri)',
              errorText: _nameError,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 14),

            // 3. Crop Type & Variety Row
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Crop Type',
                    controller: _cropTypeController,
                    hint: 'e.g. Paddy, Cotton',
                    enabled: !_isSubmitting,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Variety',
                    controller: _varietyController,
                    hint: 'e.g. High Yield, Hybrid',
                    enabled: !_isSubmitting,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Base Price & Stock Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Base Price / kg (₹) *',
                    controller: _priceController,
                    hint: '65.50',
                    errorText: _priceError,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isSubmitting,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Stock (Quintals) *',
                    controller: _stockQtlController,
                    hint: '100.00',
                    errorText: _stockError,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isSubmitting,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: Text(
                '1 Quintal = 100 kg. Global inventory pool across all fulfillment hubs.',
                style: AppTypography.caption(color: AppColors.textFaint),
              ),
            ),

            // 5. Grade Pricing Section
            _buildGradePricingSection(),
            const SizedBox(height: 16),

            // 6. Max Order Quantity
            AppTextField(
              label: 'Maximum Order Quantity (Kg)',
              controller: _maxOrderController,
              hint: 'e.g. 50.00 (leave blank for unlimited)',
              errorText: _maxOrderError,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSubmitting,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Text(
                'Maximum kg a farmer can purchase in one order.',
                style: AppTypography.caption(color: AppColors.textFaint),
              ),
            ),

            // 7. Multi-Warehouse Selection Checkboxes
            _buildWarehouseSection(),
            const SizedBox(height: 16),

            // 8. Description
            AppTextField(
              label: 'Description',
              controller: _descController,
              hint: 'High yield pest resistant variety details...',
              maxLines: 2,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 14),

            // 9. Catalog Availability Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catalog Availability',
                        style: AppTypography.bodyMedium(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _isActive ? 'Visible to farmers for purchase' : 'Hidden from farmer catalog',
                        style: AppTypography.caption(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _isActive,
                  activeThumbColor: AppColors.canopy,
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _isActive = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_submitError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.badLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.bad.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _submitError!,
                  style: AppTypography.bodySmall(color: AppColors.bad),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Add Seed to Catalog',
                        style: AppTypography.button(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildImageSection() {
    final hasImage = _imageUrlController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Seed Product Image',
                  style: AppTypography.caption(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasImage)
                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() {
                            _imageUrlController.clear();
                            _showImageInput = true;
                          }),
                  icon: const Icon(Icons.close, size: 14, color: AppColors.bad),
                  label: Text('Remove', style: AppTypography.caption(color: AppColors.bad)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  _imageUrlController.text.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.line,
                    child: Center(
                      child: Text(
                        'Image Preview Unavailable',
                        style: AppTypography.caption(color: AppColors.textFaint),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _imageUrlController.text.trim(),
              style: AppTypography.caption(color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            if (!_showImageInput) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final enterUrlButton = OutlinedButton.icon(
                    onPressed: () => setState(() => _showImageInput = true),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text(
                      'Enter Image URL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.line),
                    ),
                  );
                  final uploadButton = widget.onUploadImage == null
                      ? null
                      : ElevatedButton.icon(
                          onPressed: _isUploading ? null : _handleImageUpload,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Upload Image',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.canopy,
                            foregroundColor: Colors.white,
                          ),
                        );

                  if (constraints.maxWidth < 260) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        enterUrlButton,
                        if (uploadButton != null) ...[
                          const SizedBox(height: 8),
                          uploadButton,
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: enterUrlButton),
                      if (uploadButton != null) ...[
                        const SizedBox(width: 8),
                        Expanded(child: uploadButton),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Image URL',
                      controller: _imageUrlController,
                      hint: 'https://.../seed.jpg',
                      enabled: !_isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    child: ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.canopy,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Text(
                        'Preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],

          if (_uploadError != null) ...[
            const SizedBox(height: 6),
            Text(
              _uploadError!,
              style: AppTypography.caption(color: AppColors.bad),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradePricingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined, size: 16, color: AppColors.canopy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Grade Pricing (₹/kg) — Optional',
                  style: AppTypography.bodySmall(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Configure tiered pricing for Grade A, B, and C grain quality tiers.',
            style: AppTypography.caption(color: AppColors.textFaint),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Grade A',
                  controller: _priceGradeAController,
                  hint: '75.00',
                  errorText: _gradeAError,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  label: 'Grade B',
                  controller: _priceGradeBController,
                  hint: '70.00',
                  errorText: _gradeBError,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  label: 'Grade C',
                  controller: _priceGradeCController,
                  hint: '65.00',
                  errorText: _gradeCError,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSubmitting,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSection() {
    final warehouses = widget.availableWarehouses;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warehouse_outlined, size: 16, color: AppColors.canopy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Fulfillment Warehouses (Multi-Select)',
                  style: AppTypography.bodySmall(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Check all regional warehouses where farmers can collect this seed product.',
            style: AppTypography.caption(color: AppColors.textFaint),
          ),
          const SizedBox(height: 10),

          if (warehouses.isEmpty) ...[
            Text(
              'No warehouses currently loaded from backend.',
              style: AppTypography.caption(color: AppColors.textFaint)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ] else ...[
            Column(
              children: warehouses.map((w) {
                final isChecked = _selectedWarehouseIds.contains(w.id);
                return InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            if (isChecked) {
                              _selectedWarehouseIds.remove(w.id);
                            } else {
                              _selectedWarehouseIds.add(w.id);
                            }
                          });
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.canopy,
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  setState(() {
                                    if (val == true) {
                                      if (!_selectedWarehouseIds.contains(w.id)) {
                                        _selectedWarehouseIds.add(w.id);
                                      }
                                    } else {
                                      _selectedWarehouseIds.remove(w.id);
                                    }
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.name,
                                style: AppTypography.bodySmall(
                                  color: AppColors.text,
                                  fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              if (w.location != null && w.location!.isNotEmpty)
                                Text(
                                  w.location!,
                                  style: AppTypography.caption(color: AppColors.textFaint),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
