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
  int _selectedTab = 0; // 0: Perangkat, 1: Layanan
  List<Map<String, dynamic>> _deviceCategories = [];
  List<Map<String, dynamic>> _serviceCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.repairService.getCategories(),
      widget.repairService.getServiceCategories(),
    ]);
    if (mounted) {
      setState(() {
        _deviceCategories = results[0];
        _serviceCategories = results[1];
        _isLoading = false;
      });
    }
  }

  void _showAddDeviceCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Perangkat'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori Perangkat',
            hintText: 'Contoh: Konsol Game, Drone, Smartwatch',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan',
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await widget.repairService.createCategory(ctrl.text.trim());
              _loadAll();
            },
          ),
        ],
      ),
    );
  }

  void _showAddServiceCategoryDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Layanan Servis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Layanan', hintText: 'Contoh: Ganti Baterai'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Dasar (Rp)', hintText: '250000'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Keterangan Singkat', hintText: 'Garansi dan cakupan perbaikan'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan Layanan',
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
              Navigator.pop(ctx);
              await widget.repairService.createServiceCategory(
                name: nameCtrl.text.trim(),
                basePrice: price,
                description: descCtrl.text.trim(),
              );
              _loadAll();
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
                  Text('Manajemen Kategori', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Kelola master kategori perangkat dan paket layanan servis',
                      style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                ],
              ),
              const Spacer(),
              ReparoButton(
                label: _selectedTab == 0 ? 'Tambah Kategori Perangkat' : 'Tambah Layanan',
                icon: Icons.add,
                onPressed: _selectedTab == 0 ? _showAddDeviceCategoryDialog : _showAddServiceCategoryDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Segmented Tabs
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Kategori Perangkat'), icon: Icon(Icons.devices_outlined)),
              ButtonSegment(value: 1, label: Text('Kategori Layanan Servis'), icon: Icon(Icons.miscellaneous_services_outlined)),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_selectedTab == 0)
            _buildDeviceCategoriesList()
          else
            _buildServiceCategoriesList(),
        ],
      ),
    );
  }

  Widget _buildDeviceCategoriesList() {
    if (_deviceCategories.isEmpty) {
      return _buildEmpty('Belum ada kategori perangkat.');
    }
    return Container(
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _deviceCategories.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: ReparoTheme.rule),
        itemBuilder: (context, index) {
          final cat = _deviceCategories[index];
          final isActive = cat['is_active'] != false;
          final id = cat['id'].toString();

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: ReparoTheme.surfaceRaised,
              child: Icon(Icons.devices, color: ReparoTheme.accent, size: 20),
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
                    _loadAll();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCategoriesList() {
    if (_serviceCategories.isEmpty) {
      return _buildEmpty('Belum ada kategori layanan servis.');
    }
    return Container(
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _serviceCategories.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: ReparoTheme.rule),
        itemBuilder: (context, index) {
          final s = _serviceCategories[index];
          final isActive = s['is_active'] != false;
          final id = s['id'].toString();
          final price = (s['base_price'] as num?)?.toInt() ?? 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: ReparoTheme.surfaceRaised,
              child: Icon(Icons.build, color: ReparoTheme.statusWarning, size: 20),
            ),
            title: Text(s['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Mulai Rp $price — ${s['description'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
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
                    await widget.repairService.toggleServiceCategory(id, val);
                    _loadAll();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: ReparoTheme.surface, borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel)),
      child: Center(child: Text(msg)),
    );
  }
}
