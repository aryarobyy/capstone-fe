import 'package:flutter/foundation.dart';
import '../../../core/network/rpc_client.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService notificationService;

  NotificationProvider({required this.notificationService});

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _items = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get items => _items;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> fetch() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await notificationService.list();
      if (response.success) {
        _items = response.data ?? const [];
      } else {
        _errorMessage = response.message;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
    } catch (e) {
      _errorMessage = 'Gagal memuat notifikasi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks it read right away and rolls back if the server refuses.
  Future<void> markRead(int id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0 || _items[index].isRead) return;
    final before = _items[index];
    _items = [..._items]..[index] = before.asRead();
    notifyListeners();
    try {
      final response = await notificationService.markRead(id);
      if (response.success) return;
    } catch (_) {}
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) {
      _items = [..._items]..[i] = before;
      notifyListeners();
    }
  }
}
