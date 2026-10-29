import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../area/models/sensor_model.dart';
import '../models/alert_rule_model.dart';
import '../providers/monitoring_provider.dart';

class AlertRuleDialog extends StatefulWidget {
  final SensorModel sensor;

  const AlertRuleDialog({super.key, required this.sensor});

  @override
  State<AlertRuleDialog> createState() => _AlertRuleDialogState();
}

class _AlertRuleDialogState extends State<AlertRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _minutes = TextEditingController(text: '5');
  String _parameter = 'temperature';
  bool _enabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<MonitoringProvider>();
    setState(() => _loaded = false);
    final success = await provider.fetchAlertRules(widget.sensor.id);
    if (!mounted) return;
    setState(() {
      _loaded = success;
      if (success) {
        _selectParameter(provider.alertRules.isNotEmpty
            ? provider.alertRules.first.parameter
            : _parameter);
      }
    });
  }

  AlertRuleModel? _existingRule() {
    for (final rule in context.read<MonitoringProvider>().alertRules) {
      if (rule.sensorId == widget.sensor.id && rule.parameter == _parameter) {
        return rule;
      }
    }
    return null;
  }

  void _selectParameter(String parameter) {
    _parameter = parameter;
    final rule = _existingRule();
    _min.text = rule?.minValue?.toString() ?? '';
    _max.text = rule?.maxValue?.toString() ?? '';
    _minutes.text = rule == null ? '5' : (rule.durationSeconds / 60).toString();
    _enabled = rule?.enabled ?? true;
  }

  double? _number(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  String? _validateBound(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = _number(value);
    return number == null || !number.isFinite ? 'Masukkan angka yang valid' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<MonitoringProvider>();
    final existing = _existingRule();
    final success = await provider.saveAlertRule(AlertRuleModel(
      sensorId: widget.sensor.id,
      parameter: _parameter,
      minValue: _number(_min.text),
      maxValue: _number(_max.text),
      durationSeconds: (_number(_minutes.text)! * 60).round(),
      cooldownSeconds: existing?.cooldownSeconds ?? 600,
      maxGapSeconds: existing?.maxGapSeconds ?? 300,
      enabled: _enabled,
    ));
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aturan tersimpan. Riwayat dibuat saat batas dan durasi terpenuhi.'),
      ));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonitoringProvider>();
    final busy = provider.isSavingRule;
    final unit = _parameter == 'temperature' ? '°C' : _parameter == 'humidity' ? '%' : 'ADC';
    return PopScope(
      canPop: !busy,
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Expanded(child: Text('Aturan Peringatan', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                IconButton(onPressed: busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
              ]),
              Text('${widget.sensor.name} (ID ${widget.sensor.id})'),
              const SizedBox(height: 16),
              if (provider.isLoadingRules)
                const Center(child: CircularProgressIndicator())
              else if (!_loaded) ...[
                Text(provider.ruleErrorMessage ?? 'Gagal memuat aturan.'),
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              ] else Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_parameter),
                    initialValue: _parameter,
                    decoration: const InputDecoration(labelText: 'Parameter'),
                    items: const [
                      DropdownMenuItem(value: 'temperature', child: Text('Suhu (°C)')),
                      DropdownMenuItem(value: 'humidity', child: Text('Kelembapan udara (%)')),
                      DropdownMenuItem(value: 'soil_moisture', child: Text('Tanah (ADC mentah)')),
                    ],
                    onChanged: busy ? null : (value) {
                      if (value != null) setState(() => _selectParameter(value));
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Batas minimum ($unit, opsional)', controller: _min,
                    enabled: !busy, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: _validateBound),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Batas maksimum ($unit, opsional)', controller: _max,
                    enabled: !busy, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (value) {
                      final error = _validateBound(value);
                      if (error != null) return error;
                      if (_min.text.trim().isEmpty && _max.text.trim().isEmpty) return 'Isi minimal satu batas';
                      final min = _number(_min.text);
                      final max = _number(_max.text);
                      if (min != null && max != null && min >= max) return 'Maksimum harus lebih besar dari minimum';
                      return null;
                    }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Durasi pelanggaran (menit)', controller: _minutes,
                    enabled: !busy, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final minutes = _number(value ?? '');
                      return minutes == null || !minutes.isFinite || minutes < 0 || minutes > 1440
                        ? 'Isi durasi 0 sampai 1440 menit' : null;
                    }),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Aturan aktif'),
                    value: _enabled, onChanged: busy ? null : (v) => setState(() => _enabled = v)),
                  const Text('Riwayat dibuat jika nilai terus di luar batas selama durasi tersebut. Mengubah aturan memulai ulang akumulasi.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (provider.ruleErrorMessage != null) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(provider.ruleErrorMessage!, style: const TextStyle(color: AppColors.error))),
                  const SizedBox(height: 20),
                  AppButton(text: 'Simpan Aturan', onPressed: busy ? null : _save, isLoading: busy,
                    backgroundColor: AppColors.areaAccent, borderRadius: 24),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
