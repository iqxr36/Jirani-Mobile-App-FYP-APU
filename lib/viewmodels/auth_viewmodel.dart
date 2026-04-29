import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _authSubscription = _repository.authStateChanges.listen(_onAuthStateChanged);
    _loadCurrentUser();
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError(notify: false);

    try {
      _currentUser = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError(notify: false);

    try {
      _currentUser = await _repository.login(
        email: email,
        password: password,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    clearError(notify: false);

    try {
      await _repository.logout();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _repository.getCurrentAppUser();
      notifyListeners();
    } catch (_) {
      // keep silent on startup profile fetch errors
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    try {
      _currentUser = await _repository.getCurrentAppUser();
      notifyListeners();
    } catch (_) {
      // ignore transient failures from background auth state updates
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
