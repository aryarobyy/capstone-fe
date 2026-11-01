import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/network/rpc_client.dart';
import '../models/history_filter_params.dart';
import '../models/history_item_model.dart';
import '../services/history_service.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryService historyService;

  HistoryProvider({required this.historyService});

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isDeleting = false;
  String? _errorMessage;

  List<HistoryItemModel> _histories = [];
  HistoryItemModel? _selectedHistory;
  int _total = 0;
  HistoryFilterParams _filterParams = const HistoryFilterParams();

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  List<HistoryItemModel> get histories => _histories;
  HistoryItemModel? get selectedHistory => _selectedHistory;
  int get total => _total;
  HistoryFilterParams get filterParams => _filterParams;
  bool get hasMore => _histories.length < _total;

  void setFilterParams(HistoryFilterParams params) {
    _filterParams = params;
    notifyListeners();
  }

  /// [status] is the backend enum (`FATAL|CRITICAL|WARNING|NORMAL`); null clears it.
  void setStatus(String? status) => _refilter(status: status, date: _filterParams.date);

  /// [date] is a single `YYYY-MM-DD` day; null clears it.
  void setDate(String? date) => _refilter(status: _filterParams.status, date: date);

  // copyWith can't clear a field (`??`), so the params are rebuilt here.
  void _refilter({String? status, String? date}) {
    final p = _filterParams;
    _filterParams = HistoryFilterParams(
      sensorId: p.sensorId,
      parameter: p.parameter,
      status: status,
      date: date,
      limit: p.limit,
    );
    fetchHistories(refresh: true);
  }

  void resetFilter() {
    _filterParams = const HistoryFilterParams();
    notifyListeners();
    fetchHistories(refresh: true);
  }

  Future<void> fetchHistories({bool refresh = false}) async {
    if (refresh) {
      stopWatching(); // the filter may have changed; resubscribed once the list loads
      _filterParams = _filterParams.copyWith(index: 0);
      // Drop stale rows so a failed refetch never shows data for another filter.
      _histories = [];
      _total = 0;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await historyService.getHistoryList(_filterParams);
      if (response.success && response.data != null) {
        _histories = response.data!.data;
        _total = response.data!.total;
        if (refresh) _watchNew();
      } else {
        _errorMessage = response.message;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
    } catch (e) {
      _errorMessage = 'Gagal mengambil riwayat insiden: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  StreamSubscription<HistoryItemModel>? _watchSub;
  Timer? _watchRetry;

  /// Prepends anomalies recorded after the newest one shown, for the current filter.
  /// Resuming from that id also covers anomalies recorded while reconnecting.
  void _watchNew() {
    stopWatching();
    final newestId = _histories.fold<int>(0, (m, h) => h.id > m ? h.id : m);
    _watchSub = historyService.watchNew(_filterParams, afterId: newestId).listen(
      (item) {
        if (_histories.any((h) => h.id == item.id)) return;
        _histories = [item, ..._histories];
        _total++;
        notifyListeners();
      },
      onError: (_) => _retryWatch(),
      onDone: _retryWatch,
      cancelOnError: true,
    );
  }

  void _retryWatch() {
    _watchSub = null;
    _watchRetry = Timer(const Duration(seconds: 3), _watchNew);
  }

  void stopWatching() {
    _watchRetry?.cancel();
    _watchRetry = null;
    _watchSub?.cancel();
    _watchSub = null;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextIndex = _filterParams.index + _filterParams.limit;
    final nextParams = _filterParams.copyWith(index: nextIndex);

    try {
      final response = await historyService.getHistoryList(nextParams);
      if (response.success && response.data != null) {
        _histories.addAll(response.data!.data);
        _filterParams = nextParams;
        _total = response.data!.total;
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> fetchHistoryDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await historyService.getHistoryDetail(id);
      if (response.success && response.data != null) {
        _selectedHistory = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengambil detail riwayat: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHistory(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await historyService.deleteHistory(id);
      if (response.success) {
        _histories.removeWhere((item) => item.id == id);
        _total = (_total - 1).clamp(0, double.infinity).toInt();
        if (_selectedHistory?.id == id) {
          _selectedHistory = null;
        }
        _isDeleting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isDeleting = false;
        notifyListeners();
        return false;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      _isDeleting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menghapus riwayat: $e';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }
}
