import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/area_provider.dart';
import '../models/area_model.dart';
import '../models/sensor_model.dart';

class AddSensorModal extends StatefulWidget {
  final int? initialAreaId;

  /// When provided the modal edits that sensor instead of creating a new one.
  final SensorModel? sensor;

  const AddSensorModal({super.key, this.initialAreaId, this.sensor});

  @override
  State<AddSensorModal> createState() => _AddSensorModalState();
}

class _AddSensorModalState extends State<AddSensorModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedAreaId;

  bool get _isEdit => widget.sensor != null;

  @override
  void initState() {
    super.initState();
    final sensor = widget.sensor;
    _selectedAreaId = sensor?.areaId ?? widget.initialAreaId;
    if (sensor != null) {
      _nameController.text = sensor.name;
      _codeController.text = sensor.code;
      _descriptionController.text = sensor.description ?? '';
    }

    // If no initial area is selected, try to select the first one if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedAreaId == null) {
        final provider = context.read<AreaProvider>();
        if (provider.areas.isNotEmpty) {
          setState(() {
            _selectedAreaId = provider.areas.first.id;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);

    if (_selectedAreaId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Silakan pilih area terlebih dahulu"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<AreaProvider>();
    final navigator = Navigator.of(context);
    final description = _descriptionController.text.trim();

    final success = _isEdit
        ? await provider.updateSensor(
            id: widget.sensor!.id,
            name: _nameController.text.trim(),
            code: _codeController.text.trim(),
            areaId: _selectedAreaId!,
            description: description.isNotEmpty ? description : null,
          )
        : await provider.createSensor(
            name: _nameController.text.trim(),
            code: _codeController.text.trim(),
            areaId: _selectedAreaId!,
            description: description.isNotEmpty ? description : null,
          );

    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? "Berhasil memperbarui sensor" : "Berhasil menambahkan sensor",
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                (_isEdit ? "Gagal memperbarui sensor" : "Gagal menambahkan sensor"),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AreaProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEdit ? "Edit Sensor" : "Tambah Sensor",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: "Nama Sensor",
                  hintText: "Contoh: Sensor Suhu 1",
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama sensor tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Kode Sensor",
                  hintText: "Contoh: ESP32-001",
                  controller: _codeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode sensor tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Area Dropdown
                const Text(
                  "Pilih Area",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      // DropdownButton asserts unless the value matches exactly
                      // one item, so fall back to the hint when the sensor's
                      // area is not in the loaded list.
                      value: provider.areas.any((a) => a.id == _selectedAreaId)
                          ? _selectedAreaId
                          : null,
                      hint: const Text(
                        "Pilih Area",
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      items: provider.areas.map((AreaModel area) {
                        return DropdownMenuItem<int>(
                          value: area.id,
                          child: Text(
                            area.name.isNotEmpty ? area.name : "Area ${area.id}",
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedAreaId = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Deskripsi (Opsional)",
                  hintText: "Masukkan deskripsi sensor",
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: _isEdit ? "Perbarui Sensor" : "Simpan Sensor",
                  onPressed: provider.isSaving ? null : _submit,
                  isLoading: provider.isSaving,
                  backgroundColor: AppColors.areaAccent,
                  textColor: Colors.white,
                  borderRadius: 24.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
