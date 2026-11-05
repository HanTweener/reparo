import 'package:flutter/material.dart';
import '../services/cashier_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';

class CashierBookingScreen extends StatefulWidget {
  final CashierService cashierService;
  final ValueChanged<String> onNavigate;

  const CashierBookingScreen({
    super.key,
    required this.cashierService,
    required this.onNavigate,
  });

  @override
  State<CashierBookingScreen> createState() => _CashierBookingScreenState();
}

class _CashierBookingScreenState extends State<CashierBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _deviceNameCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();

  List<Map<String, dynamic>> _deviceCategories = [];
  List<Map<String, dynamic>> _serviceCategories = [];
  String? _selectedCategoryId;
  String _selectedServiceCode = 'MAINTENANCE';
  DateTime _arrivalDate = DateTime.now();
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
    final results = await Future.wait([
      widget.cashierService.getDeviceCategories(),
      widget.cashierService.getServiceCategories(),
    ]);
    if (mounted) {
      setState(() {
        _deviceCategories = results[0];
        _serviceCategories = results[1];
        if (_deviceCategories.isNotEmpty) {
          _selectedCategoryId = _deviceCategories.first['id'].toString();
        }
        if (_serviceCategories.isNotEmpty) {
          _selectedServiceCode = _serviceCategories.first['code'] ?? 'MAINTENANCE';
        }
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      final dateStr =
          '${_arrivalDate.year}-${_arrivalDate.month.toString().padLeft(2, '0')}-${_arrivalDate.day.toString().padLeft(2, '0')}';
      final res = await widget.cashierService.createBooking(
        customerName: _customerNameCtrl.text.trim(),
        customerEmail: _customerEmailCtrl.text.trim().isNotEmpty ? _customerEmailCtrl.text.trim() : null,
        deviceName: _deviceNameCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        serviceCode: _selectedServiceCode,
        issueDescription: _issueCtrl.text.trim(),
        arrivalDate: dateStr,
      );
      setState(() => _isSubmitting = false);

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['data']?['message'] ?? 'Booking walk-in kasir berhasil dicatat.')),
          );
          widget.onNavigate('cashier_queue');
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
                    const Text('Penerimaan Unit (Walk-in Kasir)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => widget.onNavigate('cashier_queue'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Catat penerimaan unit langsung di meja kasir. Otomatis masuk ke antrean kasir dan antrean global teknisi.',
                  style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                ),
                const SizedBox(height: 20),
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
                        decoration: const InputDecoration(labelText: 'Email Pelanggan (Opsional)', hintText: 'nama@example.com'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama / Model Perangkat (Wajib)', hintText: 'Contoh: Asus ROG Zephyrus G14'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama perangkat wajib diisi.' : null,
                ),
                const SizedBox(height: 16),
                if (_deviceCategories.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Kategori Perangkat'),
                    items: _deviceCategories
                        .map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'] ?? '')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_serviceCategories.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedServiceCode,
                    decoration: const InputDecoration(labelText: 'Jenis Layanan Servis'),
                    items: _serviceCategories
                        .map((s) => DropdownMenuItem(value: s['code'].toString(), child: Text('${s['name']} (Mulai Rp ${s['base_price']})')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedServiceCode = v);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _issueCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Keluhan / Deskripsi Masalah (Wajib)', hintText: 'Jelaskan kerusakan unit yang dilaporkan...'),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Keluhan minimal 5 karakter.' : null,
                ),
                const SizedBox(height: 16),
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
                    decoration: const InputDecoration(labelText: 'Tanggal Masuk / Janji Kedatangan', suffixIcon: Icon(Icons.calendar_today, size: 18)),
                    child: Text('${_arrivalDate.day}/${_arrivalDate.month}/${_arrivalDate.year}', style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onNavigate('cashier_queue'),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ReparoButton(
                        label: 'Simpan Pesanan Kasir',
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

