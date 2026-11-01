import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../providers/history_provider.dart';
import '../models/history_item_model.dart';
import '../widgets/status_badge.dart';

class RiwayatScreen extends StatefulWidget {
  static const routeName = '/riwayat';

  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late final HistoryProvider _historyProvider;

  @override
  void initState() {
    super.initState();
    _historyProvider = context.read<HistoryProvider>();
    // A refresh also opens the live stream for new anomalies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _historyProvider.fetchHistories(refresh: true);
    });
  }

  @override
  void dispose() {
    _historyProvider.stopWatching();
    super.dispose();
  }

  String _formatDateYMD(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Backend filters one calendar day (`started_at::date = date`), not a range.
  Future<void> _selectDate(BuildContext context, HistoryProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) provider.setDate(_formatDateYMD(picked));
  }

  void _showStatusFilter(BuildContext context, HistoryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Status",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final (label, value) in const [
                ("Semua Status", null),
                ("Fatal", "FATAL"),
                ("Kritis", "CRITICAL"),
                ("Waspada", "WARNING"),
                ("Normal", "NORMAL"),
              ])
                ListTile(
                  title: Text(label),
                  onTap: () {
                    provider.setStatus(value);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final histories = provider.histories;

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
          "Riwayat Kejadian",
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
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                _buildFilterButton(
                  icon: Icons.calendar_today_outlined,
                  label: "Date",
                  onTap: () => _selectDate(context, provider),
                ),
                if (provider.filterParams.date != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: InputChip(
                      label: Text(provider.filterParams.date!),
                      onDeleted: () => provider.setDate(null),
                    ),
                  ),
                const SizedBox(width: 10),
                _buildFilterButton(
                  icon: Icons.filter_alt_outlined,
                  label: "Status",
                  onTap: () => _showStatusFilter(context, provider),
                ),
              ],
            ),
          ),
          
          // List View
          Expanded(
            child: provider.isLoading && histories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : histories.isEmpty
                    ? Center(
                        child: Text(
                          provider.errorMessage ?? "Belum ada riwayat kejadian.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: provider.errorMessage != null
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchHistories(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: histories.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == histories.length) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Center(
                                  child: provider.isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : TextButton(
                                          onPressed: provider.loadMore,
                                          child: const Text("Muat lebih banyak"),
                                        ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildHistoryCard(histories[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItemModel item) {
    String dateStr = "N/A";
    final started = item.startedAt?.toLocal();
    if (started != null) {
      final date = started;
      const months = ["", "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
      dateStr = "${date.day} ${months[date.month]} ${date.year}";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Column(
              children: [
                // History only carries sensor_id; the area is not in the payload.
                _buildCardRow("ID Sensor", "${item.sensorId}"),
                const SizedBox(height: 6),
                _buildCardRow("Sensor", item.parameter.isNotEmpty ? item.parameter : "-"),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    StatusBadge(item.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
