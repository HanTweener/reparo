import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../theme/reparo_theme.dart';
import '../widgets/status_badge.dart';

class UserProfileScreen extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onSignOut;
  final ValueChanged<String> onSwitchRole;
  final VoidCallback onBack;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.onSwitchRole,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ReparoTheme.surface,
            borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
            border: Border.all(color: ReparoTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
                  const SizedBox(width: 8),
                  const Text('Profil Akun Pengguna', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: ReparoTheme.accent.withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ReparoTheme.accent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(user.email, style: const TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
              ),
              const SizedBox(height: 8),
              Center(
                child: StatusBadge(label: user.roleLabel, variant: BadgeVariant.accent),
              ),
              const SizedBox(height: 24),
              const Divider(color: ReparoTheme.rule),
              const SizedBox(height: 16),
              _buildInfoRow('ID Pengguna', '#${user.id}'),
              const SizedBox(height: 10),
              _buildInfoRow('Status Akun', user.isActive ? 'Aktif' : 'Nonaktif'),
              const SizedBox(height: 10),
              _buildInfoRow('Status Verifikasi', user.emailVerifiedAt != null ? 'Terverifikasi' : 'Belum Diverifikasi'),
              const SizedBox(height: 24),
              const Divider(color: ReparoTheme.rule),
              const SizedBox(height: 16),
              const Text('GANTI AKUN DEMO SINTETIS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ReparoTheme.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildRoleBtn('Pelanggan', 'CUSTOMER'),
                  _buildRoleBtn('Teknisi', 'TECHNICIAN'),
                  _buildRoleBtn('Kasir', 'CASHIER'),
                  _buildRoleBtn('Admin', 'ADMIN'),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 16, color: ReparoTheme.statusError),
                  label: const Text('Keluar dari Akun', style: TextStyle(color: ReparoTheme.statusError)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ReparoTheme.statusError),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onSignOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRoleBtn(String label, String code) {
    final isCur = user.roleCode == code;
    return ChoiceChip(
      label: Text(label),
      selected: isCur,
      selectedColor: ReparoTheme.accent,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isCur ? Colors.white : ReparoTheme.textPrimary,
        fontWeight: isCur ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => onSwitchRole(code),
    );
  }
}

