import 'package:flutter/material.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';

class AdminBookingScreen extends StatefulWidget {
  final RepairService repairService;
  final ValueChanged<String> onNavigate;

  const AdminBookingScreen({
    super.key,
    required this.repairService,
    required this.onNavigate,
  });

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _deviceNameCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();
  DateTime _arrivalDate = DateTime.now();
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _selectedServiceCode = 'MAINTENANCE';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerEmailCtrl.dispose();
    _deviceNameCtrl.dispose();
    _issueCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = await widget.repairService.getCategories();
    if (mounted) {
      setState(() {
        _categories = list;
        if (list.isNotEmpty) _selectedCategoryId = list.first['id'].toString();
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      final dateStr =
          '${_arrivalDate.year}-${_arrivalDate.month.toString().padLeft(2, '0')}-${_arrivalDate.day.toString().padLeft(2, '0')}';
      final res = await widget.repairService.createAdminBooking(
        customerName: _customerNameCtrl.text.trim(),
        customerEmail: _customerEmailCtrl.text.trim().isNotEmpty ? _customerEmailCtrl.text.trim() : null,
        deviceName: _deviceNameCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        serviceCode: _selectedServiceCode,
        issueDescription: _issueCtrl.text.trim(),
        preferredArrivalDate: dateStr,
      );
      setState(() => _isSubmitting = false);

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['data']?['message'] ?? 'Booking walk-in berhasil dibuat.')),
          );
          widget.onNavigate('queue');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Gagal membuat booking.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ReparoTheme.surface,
            borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
            border: Border.all(color: ReparoTheme.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Penerimaan Unit (Walk-in)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => widget.onNavigate('queue'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Catat pesanan servis langsung di tempat. Pesanan otomatis masuk ke Antrean Global teknisi.',
                  style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // Customer info
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customerNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Pelanggan (Wajib)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pelanggan wajib diisi.' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _customerEmailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email Pelanggan (Opsional)',
                          hintText: 'nama@example.com',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Device name
                TextFormField(
                  controller: _deviceNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama & Tipe Perangkat (Wajib)',
                    hintText: 'Contoh: Laptop Lenovo Legion 5, MacBook Pro M1',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Perangkat wajib diisi.' : null,
                ),
                const SizedBox(height: 16),

                // Category & Service
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'] as String));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedServiceCode,
                        decoration: const InputDecoration(labelText: 'Layanan'),
                        items: const [
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Perawatan (Cleaning)')),
                          DropdownMenuItem(value: 'REPAIR', child: Text('Perbaikan Fisik')),
                          DropdownMenuItem(value: 'DIAGNOSIS', child: Text('Diagnosis Kerusakan')),
                        ],
                        onChanged: (v) => setState(() => _selectedServiceCode = v ?? 'MAINTENANCE'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Issue Description
                TextFormField(
                  controller: _issueCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Keluhan / Deskripsi Masalah (Wajib)',
                    hintText: 'Jelaskan kerusakan yang dilaporkan pelanggan...',
                  ),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Keluhan minimal 5 karakter.' : null,
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _arrivalDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 7)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _arrivalDate = picked);
                  },
                  borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Masuk / Janji Kedatangan',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${_arrivalDate.day}/${_arrivalDate.month}/${_arrivalDate.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onNavigate('queue'),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ReparoButton(
                        label: 'Simpan Pesanan',
                        isLoading: _isSubmitting,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

