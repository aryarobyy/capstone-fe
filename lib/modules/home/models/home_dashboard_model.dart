import '../../riwayat/models/history_item_model.dart';

/// Dashboard numbers, composed client-side from the area, sensor and history
/// list endpoints (the server has no `/dashboard/summary`).
class HomeDashboardModel {
  final int totalAreas;
  final int totalSensors;
  final int totalAnomaliesToday;

  /// Violations that are still ongoing (the server's `active` history filter).
  final int activeAnomalies;
  final List<HistoryItemModel> recentEvents;

  const HomeDashboardModel({
    this.totalAreas = 0,
    this.totalSensors = 0,
    this.totalAnomaliesToday = 0,
    this.activeAnomalies = 0,
    this.recentEvents = const [],
  });
}
