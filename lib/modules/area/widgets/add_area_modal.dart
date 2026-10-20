import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/area_provider.dart';

class AddAreaModal extends StatefulWidget {
  const AddAreaModal({super.key});

  @override
  State<AddAreaModal> createState() => _AddAreaModalState();
}

class _AddAreaModalState extends State<AddAreaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AreaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();

    final success = await provider.createArea(
      name: _nameController.text.trim(),
      location: location.isNotEmpty ? location : null,
      description: description.isNotEmpty ? description : null,
    );

    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Berhasil menambahkan area"),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "Gagal menambahkan area"),
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
                    const Text(
                      "Tambah Area",
                      style: TextStyle(
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama area tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Lokasi (Opsional)",
                  hintText: "Contoh: Blok A",
                  controller: _locationController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Deskripsi (Opsional)",
                  hintText: "Masukkan deskripsi area",
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: "Simpan Area",
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
