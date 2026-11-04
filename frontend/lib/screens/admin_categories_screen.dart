import 'package:flutter/material.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';

class AdminCategoriesScreen extends StatefulWidget {
  final RepairService repairService;
  final VoidCallback onBack;

  const AdminCategoriesScreen({
    super.key,
    required this.repairService,
    required this.onBack,
  });

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await widget.repairService.getCategories();
    if (mounted) setState(() { _categories = list; _isLoading = false; });
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Perangkat'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Contoh: Konsol Game, Tablet, Drone',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan',
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final res = await widget.repairService.createCategory(ctrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['data']?['message'] ?? res['error'] ?? 'Proses selesai.')),
                );
                _load();
              }
            },
          ),
        ],
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
                  Text('Master Kategori Perangkat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Kelola kategori perangkat yang dilayani oleh bengkel/toko', style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                ],
              ),
              const Spacer(),
              ReparoButton(
                label: 'Tambah Kategori',
                icon: Icons.add,
                onPressed: _showAddDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_categories.isEmpty)
            _buildEmpty()
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
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: ReparoTheme.rule),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = cat['is_active'] != false;
                  final id = cat['id'].toString();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: ReparoTheme.surfaceRaised,
                      child: const Icon(Icons.category, color: ReparoTheme.accent, size: 20),
                    ),
                    title: Text(cat['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: isActive ? 'Aktif' : 'Nonaktif',
                          variant: isActive ? BadgeVariant.success : BadgeVariant.neutral,
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: isActive,
                          activeColor: ReparoTheme.accent,
                          onChanged: (val) async {
                            await widget.repairService.toggleCategory(id, val);
                            _load();
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

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: ReparoTheme.surface, borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel)),
      child: const Center(child: Text('Belum ada kategori perangkat.')),
    );
  }
}

