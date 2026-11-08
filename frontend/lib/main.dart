import 'package:flutter/material.dart';
import 'screens/admin_accounts_screen.dart';
import 'screens/admin_booking_screen.dart';
import 'screens/admin_categories_screen.dart';
import 'screens/admin_home.dart';
import 'screens/admin_staff_screen.dart';
import 'screens/cashier_booking_screen.dart';
import 'screens/cashier_home.dart';
import 'screens/customer_booking_screen.dart';
import 'screens/customer_home.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/technician_home.dart';
import 'screens/user_profile_screen.dart';
import 'services/api_service.dart';
import 'services/cashier_service.dart';
import 'services/repair_service.dart';
import 'services/technician_service.dart';
import 'state/auth_state.dart';
import 'theme/reparo_theme.dart';
import 'widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final repairService = RepairService();
  final technicianService = TechnicianService();
  final cashierService = CashierService();
  final authState = AuthState(
    apiService: apiService,
    repairService: repairService,
    technicianService: technicianService,
    cashierService: cashierService,
  );

  runApp(ReparoApp(authState: authState));
}

class ReparoApp extends StatefulWidget {
  final AuthState authState;

  const ReparoApp({super.key, required this.authState});

  @override
  State<ReparoApp> createState() => _ReparoAppState();
}

class _ReparoAppState extends State<ReparoApp> {
  bool _isRegisterView = false;
  String _currentRoute = 'orders';

  @override
  void initState() {
    super.initState();
    widget.authState.addListener(_handleAuthChange);
  }

  @override
  void dispose() {
    widget.authState.removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authState;

    return MaterialApp(
      title: 'Reparo — Maintenance & Repair Operations',
      debugShowCheckedModeBanner: false,
      theme: ReparoTheme.lightTheme,
      home: auth.isAuthenticated
          ? AppShell(
              user: auth.currentUser!,
              currentRoute: _currentRoute,
              onNavigate: (route) => setState(() => _currentRoute = route),
              onSignOut: () {
                auth.signOut();
                setState(() => _currentRoute = 'orders');
              },
              onSwitchRole: (role) async {
                await auth.quickSwitchRole(role);
                if (mounted) {
                  setState(() => _currentRoute = (role == 'ADMIN' || role == 'CASHIER')
                      ? 'queue'
                      : ((role == 'TECHNICIAN') ? 'tasks' : 'orders'));
                }
              },
              child: _buildRoleContent(auth),
            )
          : _isRegisterView
              ? RegisterScreen(
                  authState: auth,
                  onGoToLogin: () => setState(() => _isRegisterView = false),
                )
              : LoginScreen(
                  authState: auth,
                  onGoToRegister: () => setState(() => _isRegisterView = true),
                ),
    );
  }

  Widget _buildRoleContent(AuthState auth) {
    final user = auth.currentUser!;

    if (_currentRoute == 'profile') {
      return UserProfileScreen(
        user: user,
        onSignOut: () {
          auth.signOut();
          setState(() => _currentRoute = 'orders');
        },
        onSwitchRole: (role) async {
          await auth.quickSwitchRole(role);
          if (mounted) {
            setState(() {
              if (role == 'ADMIN') {
                _currentRoute = 'queue';
              } else if (role == 'CASHIER') {
                _currentRoute = 'cashier_queue';
              } else if (role == 'TECHNICIAN') {
                _currentRoute = 'tasks';
              } else {
                _currentRoute = 'orders';
              }
            });
          }
        },
        onBack: () {
          setState(() {
            if (user.isAdmin) {
              _currentRoute = 'queue';
            } else if (user.isCashier) {
              _currentRoute = 'cashier_queue';
            } else if (user.isTechnician) {
              _currentRoute = 'tasks';
            } else {
              _currentRoute = 'orders';
            }
          });
        },
      );
    }

    if (user.isAdmin) {
      if (_currentRoute == 'booking') {
        return AdminBookingScreen(
          repairService: auth.repairService,
          onNavigate: (route) => setState(() => _currentRoute = route),
        );
      }
      if (_currentRoute == 'categories') {
        return AdminCategoriesScreen(
          repairService: auth.repairService,
          onBack: () => setState(() => _currentRoute = 'queue'),
        );
      }
      if (_currentRoute == 'staff') {
        return AdminStaffScreen(
          apiService: auth.apiService,
          onBack: () => setState(() => _currentRoute = 'queue'),
        );
      }
      if (_currentRoute == 'accounts') {
        return AdminAccountsScreen(
          currentUser: user,
          apiService: auth.apiService,
          onBack: () => setState(() => _currentRoute = 'queue'),
        );
      }
      return AdminHome(
        user: user,
        apiService: auth.apiService,
        repairService: auth.repairService,
        onNavigate: (route) => setState(() => _currentRoute = route),
        initialTab: _currentRoute == 'global_queue' ? 'global' : 'all',
      );
    } else if (user.isCashier) {
      if (_currentRoute == 'cashier_booking' || _currentRoute == 'booking') {
        return CashierBookingScreen(
          cashierService: auth.cashierService,
          onNavigate: (route) => setState(() => _currentRoute = route),
        );
      }
      return CashierHome(
        user: user,
        cashierService: auth.cashierService,
        onNavigate: (route) => setState(() => _currentRoute = route),
        initialTab: (_currentRoute == 'cashier_global' || _currentRoute == 'global_queue') ? 'global' : 'all',
      );
    } else if (user.isTechnician) {
      final scope = _currentRoute == 'available'
          ? 'available'
          : (_currentRoute == 'history' ? 'history' : 'assigned');
      return TechnicianHome(
        key: ValueKey('tech_${user.id}_$scope'),
        user: user,
        technicianService: auth.technicianService,
        initialScope: scope,
      );
    } else {
      if (_currentRoute == 'booking') {
        return CustomerBookingScreen(
          repairService: auth.repairService,
          onNavigate: (route) => setState(() => _currentRoute = route),
        );
      }
      return CustomerHome(
        user: user,
        repairService: auth.repairService,
        onNavigate: (route) => setState(() => _currentRoute = route),
      );
    }
  }
}
