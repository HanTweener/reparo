import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/technician_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/status_badge.dart';
import 'technician_order_card.dart';

class TechnicianHome extends StatefulWidget {
  final AuthUser user;
  final TechnicianService technicianService;
  final String initialScope;

  const TechnicianHome({
    super.key,
    required this.user,
    required this.technicianService,
    this.initialScope = 'assigned',
  });

  @override
  State<TechnicianHome> createState() => _TechnicianHomeState();
}

class _TechnicianHomeState extends State<TechnicianHome> {
  late String _currentScope;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentScope = widget.initialScope == 'available'
        ? 'available'
        : (widget.initialScope == 'history' ? 'history' : 'assigned');
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant TechnicianHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScope != widget.initialScope) {
      _currentScope = widget.initialScope == 'available'
          ? 'available'
          : (widget.initialScope == 'history' ? 'history' : 'assigned');
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final orders = await widget.technicianService.getOrders(scope: _currentScope);
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
                    Text('Portal Teknisi: ${widget.user.name}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Kelola tugas aktif, klaim antrean global, dan pantau riwayat pengerjaan.',
                        style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                  ],
                ),
              ),
              StatusBadge(
                label: '${_orders.length} Pesanan',
                variant: BadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Scope Switcher Tabs
          Wrap(
            spacing: 8,
            children: [
              _buildScopeChip('Tugas Saya', 'assigned', Icons.build_outlined),
              _buildScopeChip('Antrean Global', 'available', Icons.inbox_outlined),
              _buildScopeChip('Riwayat Selesai', 'history', Icons.history_outlined),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            _buildEmptyState()
          else
            ..._orders.map((o) => TechnicianOrderCard(
                  order: o,
                  service: widget.technicianService,
                  onRefresh: _loadOrders,
                )),
        ],
      ),
    );
  }

  Widget _buildScopeChip(String label, String scope, IconData icon) {
    final isSelected = _currentScope == scope;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : ReparoTheme.textPrimary),
      label: Text(label),
      selected: isSelected,
      selectedColor: ReparoTheme.accent,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected ? Colors.white : ReparoTheme.textPrimary,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _currentScope = scope);
          _loadOrders();
        }
      },
    );
  }

  Widget _buildEmptyState() {
    String msg = 'Belum ada pesanan perbaikan yang ditugaskan kepada Anda.';
    if (_currentScope == 'available') {
      msg = 'Antrean global kosong. Tidak ada pesanan baru yang menunggu teknisi saat ini.';
    } else if (_currentScope == 'history') {
      msg = 'Belum ada riwayat perbaikan yang diselesaikan.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: ReparoTheme.textMuted)),
      ),
    );
  }
}
