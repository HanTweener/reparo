import 'package:flutter/material.dart';
import 'screens/admin_home.dart';
import 'screens/admin_staff_screen.dart';
import 'screens/customer_booking_screen.dart';
import 'screens/customer_devices_screen.dart';
import 'screens/customer_home.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/technician_home.dart';
import 'services/api_service.dart';
import 'services/repair_service.dart';
import 'state/auth_state.dart';
import 'theme/reparo_theme.dart';
import 'widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final repairService = RepairService();
  final authState = AuthState(apiService: apiService, repairService: repairService);

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
              onSwitchRole: (role) {
                auth.quickSwitchRole(role);
                setState(() => _currentRoute = (role == 'ADMIN') ? 'queue' : ((role == 'TECHNICIAN') ? 'tasks' : 'orders'));
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

    if (user.isAdmin) {
      if (_currentRoute == 'staff') {
        return AdminStaffScreen(
          apiService: auth.apiService,
          onBack: () => setState(() => _currentRoute = 'queue'),
        );
      }
      return AdminHome(
        user: user,
        apiService: auth.apiService,
        repairService: auth.repairService,
        onNavigate: (route) => setState(() => _currentRoute = route),
      );
    } else if (user.isTechnician) {
      return TechnicianHome(user: user);
    } else {
      if (_currentRoute == 'devices') {
        return CustomerDevicesScreen(
          repairService: auth.repairService,
          onNavigate: (route) => setState(() => _currentRoute = route),
        );
      } else if (_currentRoute == 'booking') {
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
