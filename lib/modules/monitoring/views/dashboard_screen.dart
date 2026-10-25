import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../home/providers/home_provider.dart';
import '../../riwayat/widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeProvider>().fetchDashboardSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas, // #FFFFFF
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
          "Dashboard",
          style: TextStyle(
            color: AppColors.textPrimary, // #1E1E1E
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: homeProvider.fetchDashboardSummary,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (homeProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: LinearProgressIndicator(),
              ),
            if (homeProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  homeProvider.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            // Section 1: Ringkasan Kebun
            const Text(
              "Ringkasan Kebun",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetricGrid(homeProvider),

            const SizedBox(height: 28),

            // Section 2: Kejadian Terbaru
            const Text(
              "Kejadian Terbaru",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentEventsTable(homeProvider),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetricGrid(HomeProvider provider) {
    final totalArea = provider.dashboardData.totalAreas;
    final kejadianHariIni = provider.dashboardData.totalAnomaliesToday;
    final totalSensor = provider.dashboardData.totalSensors;

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          icon: Icons.home_outlined,
          label: "Area",
          value: "$totalArea",
        ),
        _buildMetricCard(
          icon: Icons.calendar_today,
          label: "Kejadian Hari Ini",
          value: "$kejadianHariIni",
        ),
        _buildMetricCard(
          icon: Icons.crop_free,
          label: "Total Sensor",
          value: "$totalSensor",
        ),
        _buildMetricCard(
          icon: Icons.warning_amber_rounded,
          label: "Anomali Aktif",
          value: "${provider.dashboardData.activeAnomalies}",
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.primaryLight, // #E8F5E9 Soft Light Mint Green
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.success, size: 24), // Using Brand Accent
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsTable(HomeProvider provider) {
    final events = provider.dashboardData.recentEvents;

    return Column(
      children: [
        // Table Header
        Row(
          children: [
            Expanded(flex: 1, child: _buildTableHeaderText("No")),
            Expanded(flex: 1, child: _buildTableHeaderText("ID")),
            Expanded(flex: 4, child: _buildTableHeaderText("Sensor")),
            Expanded(flex: 2, child: _buildTableHeaderText("Status", alignRight: true)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.border, height: 1, thickness: 1),
        const SizedBox(height: 12),
        
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              "Belum ada kejadian terbaru.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          for (var i = 0; i < events.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTableRow(
                no: "${i + 1}",
                // History only carries sensor_id; the area is not in the payload.
                sensorId: "${events[i].sensorId}",
                sensor: events[i].parameter.isNotEmpty ? events[i].parameter : "-",
                status: events[i].status,
              ),
            ),
      ],
    );
  }

  Widget _buildTableHeaderText(String text, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTableRow({
    required String no,
    required String sensorId,
    required String sensor,
    required String status,
  }) {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildTableRowText(no)),
        Expanded(flex: 1, child: _buildTableRowText(sensorId)),
        Expanded(flex: 4, child: _buildTableRowText(sensor)),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: StatusBadge(status),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRowText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

}
