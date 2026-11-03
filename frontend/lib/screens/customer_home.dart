import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/payment_service.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import 'customer_order_card.dart';

class CustomerHome extends StatefulWidget {
  final AuthUser user;
  final RepairService repairService;
  final ValueChanged<String> onNavigate;

  const CustomerHome({
    super.key,
    required this.user,
    required this.repairService,
    required this.onNavigate,
  });

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final _paymentService = PaymentService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await widget.repairService.getCustomerOrders();
    if (mounted) setState(() { _orders = list; _isLoading = false; });
  }

  void _promptCancellation(String orderId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ReparoTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet)),
        title: const Text('Ajukan Pembatalan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pembatalan hanya dapat diajukan sebelum pemeriksaan/diagnosis dimulai. Permohonan Anda akan ditinjau oleh Admin.',
              style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Alasan Pembatalan (Opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          ReparoButton(
            label: 'Ajukan Pembatalan',
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await widget.repairService.requestCancellation(orderId, reasonCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Permintaan dicatat.')),
                );
                _loadOrders();
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, ${widget.user.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Portal pemantauan perbaikan dan status perangkat Anda', style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ReparoButton(
                label: 'Booking Maintenance',
                icon: Icons.add,
                onPressed: () => widget.onNavigate('booking'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLifecycleBanner(),
          const SizedBox(height: 24),
          const Text('Pesanan Berjalan Anda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => CustomerOrderCard(
                order: _orders[index],
                onCancel: () => _promptCancellation(_orders[index]['id'].toString()),
                onRefresh: _loadOrders,
                paymentService: _paymentService,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: ReparoTheme.textMuted),
            const SizedBox(height: 12),
            const Text('Belum ada pesanan perbaikan aktif.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ReparoButton(label: 'Buat Booking Sekarang', onPressed: () => widget.onNavigate('booking')),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReparoTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 18, color: ReparoTheme.accent),
              SizedBox(width: 8),
              Text('Alur Siklus Hidup Pesanan Perbaikan V1', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimelineNode('BOOKED', 'Dipesan', true),
                _buildArrow(),
                _buildTimelineNode('DIAGNOSING', 'Diagnosis', false),
                _buildArrow(),
                _buildTimelineNode('IN_REPAIR', 'Perbaikan', false),
                _buildArrow(),
                _buildTimelineNode('QC', 'Quality Control', false),
                _buildArrow(),
                _buildTimelineNode('READY', 'Siap Bayar', false),
                _buildArrow(),
                _buildTimelineNode('COMPLETED', 'Serah Terima', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(String code, String label, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? ReparoTheme.accent : ReparoTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDone ? ReparoTheme.accent : ReparoTheme.border),
      ),
      child: Column(
        children: [
          Text(code, style: TextStyle(fontSize: 10, fontFamily: ReparoTheme.fontMono, fontWeight: FontWeight.w600, color: isDone ? Colors.white : ReparoTheme.textMuted)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDone ? Colors.white : ReparoTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildArrow() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.arrow_forward, size: 14, color: ReparoTheme.textMuted),
      );
}
