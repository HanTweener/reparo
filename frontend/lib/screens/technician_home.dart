import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/technician_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/status_badge.dart';
import 'technician_order_card.dart';

class TechnicianHome extends StatefulWidget {
  final AuthUser user;

  const TechnicianHome({super.key, required this.user});

  @override
  State<TechnicianHome> createState() => _TechnicianHomeState();
}

class _TechnicianHomeState extends State<TechnicianHome> {
  final _service = TechnicianService();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final orders = await _service.getAssignedOrders();
    if (mounted) setState(() { _orders = orders; _loading = false; });
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
                    Text('Tugas Teknisi: ${widget.user.name}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Daftar perbaikan aktif dan kontrol alur kerja teknis',
                        style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                  ],
                ),
              ),
              StatusBadge(
                label: '${_orders.length} Tugas Ditugaskan',
                variant: BadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            _buildEmptyState()
          else
            ..._orders.map((o) => TechnicianOrderCard(
                  order: o,
                  service: _service,
                  onRefresh: _loadOrders,
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: const Center(
        child: Text('Belum ada pesanan perbaikan yang ditugaskan kepada Anda.',
            style: TextStyle(color: ReparoTheme.textMuted)),
      ),
    );
  }
}
