import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';

class AdminStaffScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onBack;

  const AdminStaffScreen({
    super.key,
    required this.apiService,
    required this.onBack,
  });

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  List<AuthUser> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final list = await widget.apiService.getStaffList();
    if (mounted) {
      setState(() {
        _staffList = list;
        _isLoading = false;
      });
    }
  }

  void _showCreateStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'TECHNICIAN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ReparoTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet)),
          title: const Text('Buat Akun Staf Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                    decoration: const InputDecoration(labelText: 'Peran Akun Staf'),
                    items: const [
                      DropdownMenuItem(value: 'TECHNICIAN', child: Text('Teknisi (TECHNICIAN)')),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: ReparoTheme.textMuted)),
            ),
            ReparoButton(
              label: 'Simpan Staf',
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  await widget.apiService.createStaff(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                    roleCode: selectedRole,
                  );
                  _loadStaff();
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
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                tooltip: 'Kembali ke Antrian',
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manajemen Staf & Akses Peran', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Penyediaan akun Teknisi dan Administrator sesuai FEAT-001',
                      style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                ],
              ),
              const Spacer(),
              ReparoButton(
                label: 'Tambah Staf',
                icon: Icons.person_add,
                onPressed: _showCreateStaffDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
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
                itemCount: _staffList.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: ReparoTheme.rule),
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: ReparoTheme.surfaceRaised,
                      child: Icon(
                        staff.isAdmin ? Icons.admin_panel_settings : Icons.engineering,
                        color: ReparoTheme.accent,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: staff.roleLabel,
                          variant: staff.isAdmin ? BadgeVariant.warning : BadgeVariant.neutral,
                        ),
                      ],
                    ),
                    subtitle: Text(staff.email, style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(staff.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: staff.isActive ? ReparoTheme.statusSuccess : ReparoTheme.statusError,
                            )),
                        const SizedBox(width: 8),
                        Switch(
                          value: staff.isActive,
                          activeColor: ReparoTheme.accent,
                          onChanged: (val) async {
                            await widget.apiService.updateStaffStatus(staff.id, val);
                            _loadStaff();
                          },
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

