import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../providers/area_provider.dart';
import '../models/area_model.dart';
import '../models/sensor_activity_model.dart';
import '../models/sensor_model.dart';
import '../widgets/area_card.dart';
import '../widgets/sensor_card.dart';
import '../widgets/add_area_modal.dart';
import '../widgets/add_sensor_modal.dart';
import '../../monitoring/widgets/alert_rule_dialog.dart';

class AreaScreen extends StatefulWidget {
  static const routeName = '/area';

  const AreaScreen({super.key});

  @override
  State<AreaScreen> createState() => _AreaScreenState();
}

class _AreaScreenState extends State<AreaScreen> {
  static const _activityTab = 2;

  int _selectedChipIndex = 0;
  late final AreaProvider _areaProvider;

  @override
  void initState() {
    super.initState();
    _areaProvider = context.read<AreaProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _areaProvider.loadAll();
    });
  }

  @override
  void dispose() {
    _areaProvider.stopActivity();
    super.dispose();
  }

  Future<void> _refresh() => context.read<AreaProvider>().loadAll();

  /// Re-reads both lists from the API after a successful create or update.
  Future<void> _openModal(Widget modal) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => modal,
    );
    if (saved == true && mounted) {
      await _refresh();
    }
  }

  /// Shared confirmation sheet for both destructive actions.
  Future<bool> _askDelete({required String title, required String label}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          "Hapus \"$label\"? Tindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Hapus",
              style: TextStyle(color: AppColors.actionDelete),
            ),
          ),
        ],
      ),
    );

    return confirmed == true && mounted;
  }

  Future<void> _deleteSensor(SensorModel sensor) async {
    final provider = context.read<AreaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final label = sensor.name.isNotEmpty ? sensor.name : sensor.code;

    if (!await _askDelete(title: "Hapus Sensor", label: label)) return;
    final success = await provider.deleteSensor(sensor.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Sensor berhasil dihapus"
              : provider.errorMessage ?? "Gagal menghapus sensor",
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _deleteArea(AreaModel area) async {
    final provider = context.read<AreaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final label = area.name.isNotEmpty ? area.name : "Area ${area.id}";

    if (!await _askDelete(title: "Hapus Area", label: label)) return;
    final success = await provider.deleteArea(area.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Area berhasil dihapus"
              : provider.errorMessage ?? "Gagal menghapus area",
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areaProvider = context.watch<AreaProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Daftar Area",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Filter Chips and Area Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildChoiceChip("Area", 0),
                    const SizedBox(width: 8),
                    _buildChoiceChip("Sensor", 1),
                    const SizedBox(width: 8),
                    _buildChoiceChip("Aktivitas", _activityTab),
                  ],
                ),
                if (_selectedChipIndex != 0) // Sensor and Aktivitas tabs
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        // Deleting the filtered area drops its id from `areas`,
                        // so fall back to the sentinel to avoid an assertion.
                        value: areaProvider.areas.any(
                          (a) => a.id == areaProvider.sensorAreaFilter,
                        )
                            ? areaProvider.sensorAreaFilter
                            : 0,
                        hint: const Text(
                          "Area",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
                        isDense: true,
                        items: [
                          const DropdownMenuItem<int>(
                            value: 0,
                            child: Text("Semua Area"),
                          ),
                          ...areaProvider.areas.map(
                            (area) => DropdownMenuItem<int>(
                              value: area.id,
                              child: Text(area.name.isNotEmpty ? area.name : "Area ${area.id}"),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          // 0 is the "Semua Area" sentinel -> no server filter.
                          final areaId = (value == null || value == 0) ? null : value;
                          areaProvider.fetchSensors(areaId: areaId);
                          if (_selectedChipIndex == _activityTab) {
                            areaProvider.watchActivity(areaId: areaId);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // List of Areas or Sensors
          Expanded(child: _buildBody(areaProvider)),
          // Tambah Button
          if (_selectedChipIndex != _activityTab)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
              child: AppButton(
                text: _selectedChipIndex == 0 ? "Tambah Area" : "Tambah Sensor",
                onPressed: () => _openModal(
                  _selectedChipIndex == 0
                      ? const AddAreaModal()
                      : AddSensorModal(initialAreaId: areaProvider.sensorAreaFilter),
                ),
                backgroundColor: AppColors.areaAccent,
                textColor: Colors.white,
                borderRadius: 24.0,
                elevation: 1.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AreaProvider provider) {
    if (_selectedChipIndex == _activityTab) return _buildActivityList(provider);

    final isAreaTab = _selectedChipIndex == 0;
    final items = isAreaTab ? provider.areas : provider.sensors;

    if (provider.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && items.isEmpty) {
      return _buildMessage(provider.errorMessage!, showRetry: true);
    }

    if (items.isEmpty) {
      return _buildMessage(
        isAreaTab ? "Belum ada data area." : "Belum ada data sensor.",
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.areaAccent,
      child: isAreaTab
          ? _buildAreaList(provider)
          : _buildSensorList(provider),
    );
  }

  Widget _buildMessage(String text, {bool showRetry = false}) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.areaAccent,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (showRetry) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _refresh,
                child: const Text(
                  "Coba lagi",
                  style: TextStyle(color: AppColors.areaAccent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAreaList(AreaProvider provider) {
    final areas = provider.areas;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: areas.length,
      itemBuilder: (context, index) {
        final area = areas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: AreaCard(
            area: area,
            sensorsCount: provider.sensorCountOf(area.id),
            onDetailTap: () {
              setState(() => _selectedChipIndex = 1);
              provider.fetchSensors(areaId: area.id);
            },
            onEdit: () => _openModal(AddAreaModal(area: area)),
            onDelete: () => _deleteArea(area),
          ),
        );
      },
    );
  }

  Widget _buildSensorList(AreaProvider provider) {
    final sensors = provider.sensors;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.72,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        return SensorCard(
          sensor: sensor,
          areaName: provider.areaNameOf(sensor.areaId),
          onEdit: () => _openModal(AddSensorModal(sensor: sensor)),
          onDelete: () => _deleteSensor(sensor),
          onConfigureAlert: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertRuleDialog(sensor: sensor),
          ),
        );
      },
    );
  }

  Widget _buildActivityList(AreaProvider provider) {
    final items = provider.activities;
    if (items.isEmpty) {
      return _buildMessage("Menunggu data sensor...");
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final activity = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sensors, color: AppColors.areaAccent),
          title: Text(
            activity.sensorName.isNotEmpty
                ? activity.sensorName
                : "Sensor ${activity.sensorId}",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _readingText(activity),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Text(
            _clock(activity.recordedAt),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        );
      },
    );
  }

  /// Each sensor measures one thing and reports 0 for the rest, so zeros are hidden.
  String _readingText(SensorActivityModel a) {
    String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    final parts = [
      if (a.temperature != 0) "Suhu ${n(a.temperature)}°C",
      if (a.humidity != 0) "Kelembapan ${n(a.humidity)}%",
      if (a.soilMoisture != 0) "Tanah ${n(a.soilMoisture)}",
    ];
    return parts.isEmpty ? "Semua nilai 0" : parts.join(" · ");
  }

  String _clock(DateTime? t) {
    if (t == null) return "-";
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(t.hour)}:${two(t.minute)}:${two(t.second)}";
  }

  Widget _buildChoiceChip(String label, int index) {
    final isSelected = _selectedChipIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (index == _selectedChipIndex) return; // re-tap must not reset the feed
        setState(() {
          _selectedChipIndex = index;
        });
        if (index == _activityTab) {
          _areaProvider.watchActivity(areaId: _areaProvider.sensorAreaFilter);
        } else {
          _areaProvider.stopActivity();
        }
      },
      selectedColor: AppColors.areaAccent,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.areaAccent,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(
          color: AppColors.areaAccent,
        ),
      ),
      showCheckmark: false,
    );
  }
}
