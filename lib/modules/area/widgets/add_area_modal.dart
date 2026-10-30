import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/area_provider.dart';
import '../models/area_model.dart';

class AddAreaModal extends StatefulWidget {
  /// When provided the modal edits that area instead of creating a new one.
  final AreaModel? area;

  const AddAreaModal({super.key, this.area});

  @override
  State<AddAreaModal> createState() => _AddAreaModalState();
}

class _AddAreaModalState extends State<AddAreaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool get _isEdit => widget.area != null;

  @override
  void initState() {
    super.initState();
    final area = widget.area;
    if (area != null) {
      _nameController.text = area.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AreaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();

    final success = _isEdit
        ? await provider.updateArea(id: widget.area!.id, name: name)
        : await provider.createArea(name: name);

    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? "Berhasil memperbarui area" : "Berhasil menambahkan area",
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                (_isEdit ? "Gagal memperbarui area" : "Gagal menambahkan area"),
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
                      _isEdit ? "Edit Area" : "Tambah Area",
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
                  label: "Nama Area",
                  hintText: "Contoh: Area 1",
                  controller: _nameController,
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Nama area tidak boleh kosong';
                    // Server rejects anything longer with a 400.
                    if (name.length > 255) return 'Nama area maksimal 255 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: _isEdit ? "Perbarui Area" : "Simpan Area",
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
