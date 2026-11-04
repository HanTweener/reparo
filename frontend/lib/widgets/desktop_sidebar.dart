import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../theme/reparo_theme.dart';
import 'app_shell.dart';
import 'reparo_logo.dart';

class DesktopSidebar extends StatelessWidget {
  final AuthUser user;
  final String currentRoute;
  final List<NavDestination> destinations;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final ValueChanged<String> onSwitchRole;

  const DesktopSidebar({
    super.key,
    required this.user,
    required this.currentRoute,
    required this.destinations,
    required this.onNavigate,
    required this.onSignOut,
    required this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 228,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const ReparoLogo(size: 24),
                const Text(
                  'Reparo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ReparoTheme.textPrimary,
                    fontFamily: ReparoTheme.fontSans,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ReparoTheme.stateSelected,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ReparoTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ReparoTheme.rule),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: destinations.map((dest) {
                final isSelected = currentRoute == dest.routeId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected ? ReparoTheme.stateSelected : Colors.transparent,
                    borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        dest.icon,
                        size: 18,
                        color: isSelected ? ReparoTheme.textPrimary : ReparoTheme.textMuted,
                      ),
                      title: Text(
                        dest.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? ReparoTheme.textPrimary : ReparoTheme.textMuted,
                          fontFamily: ReparoTheme.fontSans,
                        ),
                      ),
                      onTap: () => onNavigate(dest.routeId),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Demo role switch quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEMO ROLE SWITCH',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ReparoTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: [
                    _buildRoleChip('Pelanggan', 'CUSTOMER'),
                    _buildRoleChip('Teknisi', 'TECHNICIAN'),
                    _buildRoleChip('Kasir', 'CASHIER'),
                    _buildRoleChip('Admin', 'ADMIN'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ReparoTheme.rule),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onNavigate('profile'),
                    borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 14, color: ReparoTheme.textMuted),
                            ],
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 11, color: ReparoTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: ReparoTheme.textMuted),
                  tooltip: 'Keluar',
                  onPressed: onSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String code) {
    final isCurrent = user.roleCode == code;
    return InkWell(
      onTap: () => onSwitchRole(code),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isCurrent ? ReparoTheme.accent : ReparoTheme.stateSelected,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isCurrent ? Colors.white : ReparoTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

