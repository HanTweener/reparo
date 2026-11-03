import 'package:flutter/material.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';

class CustomerDevicesScreen extends StatefulWidget {
  final RepairService repairService;
  final ValueChanged<String> onNavigate;

  const CustomerDevicesScreen({
    super.key,
    required this.repairService,
    required this.onNavigate,
  });

  @override
  State<CustomerDevicesScreen> createState() => _CustomerDevicesScreenState();
}

class _CustomerDevicesScreenState extends State<CustomerDevicesScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final data = await widget.repairService.getCustomerDevices();
    if (mounted) {
      setState(() {
        _devices = data;
        _isLoading = false;
      });
    }
  }

  void _showAddDeviceDialog() async {
    final categories = await widget.repairService.getCategories();
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCatId = categories.isNotEmpty ? categories.first['id'].toString() : '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ReparoTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet)),
          title: const Text('Daftarkan Perangkat Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCatId,
                    decoration: const InputDecoration(labelText: 'Kategori Perangkat'),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['name'] as String),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCatId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(labelText: 'Merek', hintText: 'Contoh: ASUS, Lenovo, Apple'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Merek wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Model / Seri', hintText: 'Contoh: ROG Zephyrus G14'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Model wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: serialCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Seri / S/N (Opsional)',
                      helperText: 'Akan disamarkan untuk privasi keamanan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Catatan Fisik (Opsional)'),
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
              label: 'Simpan Perangkat',
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  await widget.repairService.createCustomerDevice(
                    categoryId: selectedCatId,
                    brand: brandCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                    serialNumber: serialCtrl.text.trim().isEmpty ? null : serialCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  _loadDevices();
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Perangkat Saya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Daftar perangkat terdaftar yang dapat dipilih untuk perbaikan',
                      style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                ],
              ),
              ReparoButton(
                label: 'Tambah Perangkat',
                icon: Icons.add,
                onPressed: _showAddDeviceDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_devices.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ReparoTheme.surface,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
                border: Border.all(color: ReparoTheme.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.devices_other, size: 48, color: ReparoTheme.textMuted),
                    const SizedBox(height: 12),
                    const Text('Belum ada perangkat terdaftar.', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Daftarkan perangkat pertama Anda untuk memulai booking.',
                        style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                    const SizedBox(height: 16),
                    ReparoButton(label: 'Tambah Perangkat Sekarang', onPressed: _showAddDeviceDialog),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = _devices[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ReparoTheme.surface,
                    borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
                    border: Border.all(color: ReparoTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ReparoTheme.surfaceRaised,
                          borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                        ),
                        child: const Icon(Icons.laptop_mac, color: ReparoTheme.accent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d['brand']} ${d['model']}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kategori: ${d['category_name'] ?? 'Umum'} · S/N: ${d['serial_number'] ?? '—'}',
                              style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted),
                            ),
                            if (d['description'] != null && d['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(d['description'], style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
                            ],
                          ],
                        ),
                      ),
                      ReparoButton(
                        label: 'Booking Perbaikan',
                        isPrimary: false,
                        onPressed: () => widget.onNavigate('booking'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

