import 'package:flutter/material.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';

class CustomerBookingScreen extends StatefulWidget {
  final RepairService repairService;
  final ValueChanged<String> onNavigate;

  const CustomerBookingScreen({
    super.key,
    required this.repairService,
    required this.onNavigate,
  });

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));
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
          '${_preferredDate.year}-${_preferredDate.month.toString().padLeft(2, '0')}-${_preferredDate.day.toString().padLeft(2, '0')}';
      final res = await widget.repairService.createCustomerBooking(
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
            SnackBar(content: Text(res['data']?['message'] ?? 'Booking berhasil dibuat.')),
          );
          widget.onNavigate('orders');
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
          constraints: const BoxConstraints(maxWidth: 580),
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
                const Text(
                  'Buat Janji Perbaikan Baru',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ReparoTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tulis rincian perangkat dan keluhan Anda secara langsung tanpa perlu registrasi perangkat terpisah.',
                  style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                ),
                const SizedBox(height: 24),

                // Manual Device Name Input
                TextFormField(
                  controller: _deviceNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama & Tipe Perangkat (Wajib)',
                    hintText: 'Contoh: Laptop ASUS ROG Zephyrus G14, iPhone 13 Pro',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'Masukkan nama dan tipe perangkat minimal 3 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category & Service Code Selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Kategori Perangkat'),
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
                        decoration: const InputDecoration(labelText: 'Jenis Layanan'),
                        items: const [
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Perawatan (Cleaning)')),
                          DropdownMenuItem(value: 'REPAIR', child: Text('Perbaikan Komponen')),
                          DropdownMenuItem(value: 'DIAGNOSIS', child: Text('Diagnosis Menyeluruh')),
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
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Keluhan & Gejala Kerusakan (Wajib)',
                    hintText: 'Jelaskan masalah secara ringkas, misal: suhu panas, restart sendiri, layar bergaris...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 5) {
                      return 'Deskripsi keluhan minimal 5 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Arrival Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _preferredDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _preferredDate = picked);
                  },
                  borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Rencana Kedatangan Unit',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onNavigate('orders'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusControl)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ReparoButton(
                        label: 'Kirim Pemesanan',
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
