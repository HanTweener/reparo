import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../theme/reparo_theme.dart';
import 'desktop_sidebar.dart';
import 'reparo_logo.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final String routeId;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.routeId,
  });
}

class AppShell extends StatelessWidget {
  final AuthUser user;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final ValueChanged<String> onSwitchRole;
  final Widget child;

  const AppShell({
    super.key,
    required this.user,
    required this.currentRoute,
    required this.onNavigate,
    required this.onSignOut,
    required this.onSwitchRole,
    required this.child,
  });

  List<NavDestination> get _destinations {
    if (user.isAdmin) {
      return const [
        NavDestination(label: 'Antrian', icon: Icons.inbox_outlined, routeId: 'queue'),
        NavDestination(label: 'Antrean Global', icon: Icons.public_outlined, routeId: 'global_queue'),
        NavDestination(label: 'Booking', icon: Icons.add_circle_outline, routeId: 'booking'),
        NavDestination(label: 'Manajemen Kategori', icon: Icons.category_outlined, routeId: 'categories'),
        NavDestination(label: 'Staf & Performa', icon: Icons.people_outline, routeId: 'staff'),
        NavDestination(label: 'Manajemen Akun', icon: Icons.manage_accounts_outlined, routeId: 'accounts'),
      ];
    } else if (user.isCashier) {
      return const [
        NavDestination(label: 'Antrian', icon: Icons.inbox_outlined, routeId: 'queue'),
        NavDestination(label: 'Antrean Global', icon: Icons.public_outlined, routeId: 'global_queue'),
        NavDestination(label: 'Booking', icon: Icons.add_circle_outline, routeId: 'booking'),
      ];
    } else if (user.isTechnician) {
      return const [
        NavDestination(label: 'Tugas Saya', icon: Icons.build_outlined, routeId: 'tasks'),
        NavDestination(label: 'Antrean Global', icon: Icons.public_outlined, routeId: 'available'),
        NavDestination(label: 'Riwayat', icon: Icons.history_outlined, routeId: 'history'),
      ];
    } else {
      return const [
        NavDestination(label: 'Pesanan Saya', icon: Icons.receipt_long_outlined, routeId: 'orders'),
        NavDestination(label: 'Booking Baru', icon: Icons.add_circle_outline, routeId: 'booking'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ReparoTheme.breakpointDesktop;
        final isMobile = constraints.maxWidth < ReparoTheme.breakpointTablet;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildTabletLayout(context);
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: ReparoTheme.frame,
      body: Row(
        children: [
          DesktopSidebar(
            user: user,
            currentRoute: currentRoute,
            destinations: _destinations,
            onNavigate: onNavigate,
            onSignOut: onSignOut,
            onSwitchRole: onSwitchRole,
          ),
          // White work sheet inset 8px with 16px radius
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                color: ReparoTheme.surface,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
                border: Border.all(color: ReparoTheme.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: ReparoTheme.frame,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReparoLogo(size: 20),
            SizedBox(width: 8),
            Text('Reparo', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 22),
            tooltip: 'Profil Akun',
            onPressed: () => onNavigate('profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Container(
        color: ReparoTheme.surface,
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: ReparoTheme.surface,
            border: Border(top: BorderSide(color: ReparoTheme.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _destinations.indexWhere((d) => d.routeId == currentRoute).clamp(0, _destinations.length - 1),
            onTap: (index) => onNavigate(_destinations[index].routeId),
            selectedItemColor: ReparoTheme.actionPrimary,
            unselectedItemColor: ReparoTheme.textMuted,
            backgroundColor: ReparoTheme.surface,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: _destinations
                .map((d) => BottomNavigationBarItem(
                      icon: Icon(d.icon, size: 20),
                      label: d.label,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: ReparoTheme.frame,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReparoLogo(size: 20),
            SizedBox(width: 8),
            Text('Reparo', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onSignOut),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: ReparoTheme.actionPrimary),
              accountName: Text(user.name),
              accountEmail: Text('${user.email} (${user.roleLabel})'),
            ),
            Expanded(
              child: ListView(
                children: _destinations
                    .map((d) => ListTile(
                          leading: Icon(d.icon),
                          title: Text(d.label),
                          selected: currentRoute == d.routeId,
                          onTap: () {
                            Navigator.pop(context);
                            onNavigate(d.routeId);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ReparoTheme.surface,
          borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
          border: Border.all(color: ReparoTheme.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}
