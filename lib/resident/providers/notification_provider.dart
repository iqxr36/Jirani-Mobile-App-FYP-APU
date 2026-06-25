import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/data/repositories/notification_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository();

  final NotificationRepository _repository;

  StreamSubscription<List<NotificationModel>>? _notificationsSub;
  StreamSubscription<int>? _unreadSub;
  AppUser? _currentUser;
  List<NotificationModel> _notifications = const <NotificationModel>[];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void watchForUser(AppUser? user) {
    if (user?.uid == _currentUser?.uid) return;
    _currentUser = user;
    _notificationsSub?.cancel();
    _unreadSub?.cancel();

    if (user == null) {
      _notifications = const <NotificationModel>[];
      _unreadCount = 0;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _notificationsSub = _repository.watchNotifications(user.uid).listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _unreadSub = _repository.watchUnreadCount(user.uid).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<void> markRead(String notificationId) {
    return _repository.markRead(notificationId);
  }

  Future<void> markAllRead() {
    final uid = _currentUser?.uid;
    if (uid == null) return Future<void>.value();
    return _repository.markAllRead(uid);
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }
}
