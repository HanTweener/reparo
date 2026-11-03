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
  final _issueCtrl = TextEditingController();
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));
  List<Map<String, dynamic>> _devices = [];
  String? _selectedDeviceId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final list = await widget.repairService.getCustomerDevices();
    if (mounted) {
      setState(() {
        _devices = list;
        if (list.isNotEmpty) _selectedDeviceId = list.first['id'].toString();
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (_selectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan daftarkan perangkat terlebih dahulu.')),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      final dateStr = '${_preferredDate.year}-${_preferredDate.month.toString().padLeft(2, '0')}-${_preferredDate.day.toString().padLeft(2, '0')}';
      final res = await widget.repairService.bookOrder(
        deviceId: _selectedDeviceId!,
        issueDescription: _issueCtrl.text.trim(),
        preferredArrivalDate: dateStr,
      );
      setState(() => _isSubmitting = false);

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['data']['message'] ?? 'Booking berhasil dibuat.')),
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

    if (_devices.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: ReparoTheme.surface,
            borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
            border: Border.all(color: ReparoTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.devices, size: 48, color: ReparoTheme.textMuted),
              const SizedBox(height: 16),
              const Text('Belum Ada Perangkat Terdaftar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Anda harus mendaftarkan perangkat terlebih dahulu sebelum dapat membuat pesanan maintenance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
              ),
              const SizedBox(height: 20),
              ReparoButton(
                label: 'Daftarkan Perangkat Baru',
                onPressed: () => widget.onNavigate('devices'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ReparoTheme.surface,
            borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
            border: Border.all(color: ReparoTheme.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Booking Layanan Maintenance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Layanan tunggal standar Reparo untuk pemeliharaan dan perbaikan perangkat',
                  style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  value: _selectedDeviceId,
                  decoration: const InputDecoration(labelText: 'Pilih Perangkat Anda'),
                  items: _devices
                      .map((d) => DropdownMenuItem(
                            value: d['id'].toString(),
                            child: Text('${d['brand']} ${d['model']} (${d['category_name'] ?? 'Umum'})'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedDeviceId = val),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _issueCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Keluhan / Deskripsi Masalah',
                    hintText: 'Jelaskan gejala kerusakan fisik, suara, suhu, atau performa...',
                  ),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Jelaskan keluhan minimal 5 karakter' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Preferensi Tanggal Kedatangan', style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                          const SizedBox(height: 6),
                          Text(
                            '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ReparoTheme.fontMono),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Pilih Tanggal'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _preferredDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) setState(() => _preferredDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ReparoTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                  ),
                  child: const Text(
                    'Catatan: Tanggal kedatangan yang dipilih adalah permohonan. Jadwal resmi akan dikonfirmasi oleh Administrator.',
                    style: TextStyle(fontSize: 12, color: ReparoTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 24),

                ReparoButton(
                  label: 'Kirim Permohonan Booking',
                  onPressed: _submit,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

