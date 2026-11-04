import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';

class AdminAccountsScreen extends StatefulWidget {
  final AuthUser currentUser;
  final ApiService apiService;
  final VoidCallback onBack;

  const AdminAccountsScreen({
    super.key,
    required this.currentUser,
    required this.apiService,
    required this.onBack,
  });

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  List<AuthUser> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await widget.apiService.getStaffList();
    if (mounted) setState(() { _accounts = list; _isLoading = false; });
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'TECHNICIAN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Buat Akun Staf / Admin Baru'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Alamat Email'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Kata Sandi Awal'),
                    validator: (v) => (v == null || v.length < 8) ? 'Min 8 karakter' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Peran Akun'),
                    items: const [
                      DropdownMenuItem(value: 'TECHNICIAN', child: Text('Teknisi (TECHNICIAN)')),
                      DropdownMenuItem(value: 'CASHIER', child: Text('Kasir (CASHIER)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrator (ADMIN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ReparoButton(
              label: 'Simpan Akun',
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  await widget.apiService.createStaff(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                    roleCode: selectedRole,
                  );
                  _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manajemen Akun Internal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Kelola hak akses dan status aktivasi akun staf & administrator',
                      style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                ],
              ),
              const Spacer(),
              ReparoButton(
                label: 'Tambah Akun',
                icon: Icons.person_add,
                onPressed: _showCreateDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else
            Container(
              decoration: BoxDecoration(
                color: ReparoTheme.surface,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
                border: Border.all(color: ReparoTheme.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _accounts.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: ReparoTheme.rule),
                itemBuilder: (context, index) {
                  final acc = _accounts[index];
                  final isSelf = acc.id == widget.currentUser.id;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: ReparoTheme.surfaceRaised,
                      child: Icon(
                        acc.isAdmin ? Icons.admin_panel_settings : (acc.isCashier ? Icons.point_of_sale : Icons.engineering),
                        color: ReparoTheme.accent,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          const Text('(Anda)', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: ReparoTheme.textMuted)),
                        ],
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: acc.roleLabel,
                          variant: acc.isAdmin ? BadgeVariant.warning : (acc.isCashier ? BadgeVariant.accent : BadgeVariant.neutral),
                        ),
                      ],
                    ),
                    subtitle: Text(acc.email, style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          acc.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: acc.isActive ? ReparoTheme.statusSuccess : ReparoTheme.statusError,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: isSelf ? 'Anda tidak dapat menonaktifkan akun Anda sendiri' : 'Ubah status aktif akun',
                          child: Switch(
                            value: acc.isActive,
                            activeColor: ReparoTheme.accent,
                            onChanged: isSelf ? null : (val) async {
                              await widget.apiService.updateStaffStatus(acc.id, val);
                              _load();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

