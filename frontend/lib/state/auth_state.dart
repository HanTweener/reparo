import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../services/repair_service.dart';

class AuthState extends ChangeNotifier {
  final ApiService apiService;
  final RepairService repairService;
  AuthUser? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthState({
    required this.apiService,
    required this.repairService,
  });

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await apiService.login(email: email, password: password);
    _isLoading = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      _token = data['token'] as String?;
      apiService.setToken(_token);
      repairService.setToken(_token);
      _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] as String? ?? 'Gagal masuk.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await apiService.register(name: name, email: email, password: password);
    _isLoading = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      _token = data['token'] as String?;
      apiService.setToken(_token);
      repairService.setToken(_token);
      _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] as String? ?? 'Gagal mendaftar.';
      notifyListeners();
      return false;
    }
  }

  /// Quick role switcher for portfolio demo reviewers
  Future<void> quickSwitchRole(String roleCode) async {
    switch (roleCode) {
      case 'ADMIN':
        await signIn('admin@reparo.test', 'Password123!');
        break;
      case 'TECHNICIAN':
        await signIn('technician@reparo.test', 'Password123!');
        break;
      case 'CUSTOMER':
      default:
        await signIn('customer@reparo.test', 'Password123!');
        break;
    }
  }

  void signOut() {
    apiService.logout();
    _currentUser = null;
    _token = null;
    apiService.setToken(null);
    repairService.setToken(null);
    _errorMessage = null;
    notifyListeners();
  }
}
