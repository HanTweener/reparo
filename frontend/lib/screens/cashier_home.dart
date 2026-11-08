import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/cashier_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/admin_stats_bar.dart';
import '../widgets/status_badge.dart';
import 'cashier_order_dialogs.dart';

class CashierHome extends StatefulWidget {
  final AuthUser user;
  final CashierService cashierService;
  final ValueChanged<String> onNavigate;
  final String initialTab;

  const CashierHome({
    super.key,
    required this.user,
    required this.cashierService,
    required this.onNavigate,
    this.initialTab = 'all',
  });

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _stats = {'incoming': 0, 'in_progress': 0, 'completed': 0, 'total': 0};
  String _statsPeriod = 'all';
  late String _currentTab;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadAll();
  }

  @override
  void didUpdateWidget(covariant CashierHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentTab = widget.initialTab;
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final ordersFuture = _currentTab == 'global'
        ? widget.cashierService.getGlobalQueue()
        : widget.cashierService.getOrders();
    final results = await Future.wait([
      ordersFuture,
      widget.cashierService.getStatistics(period: _statsPeriod),
    ]);
    if (mounted) {
      setState(() {
        _orders = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String p) async {
    setState(() => _statsPeriod = p);
    final stats = await widget.cashierService.getStatistics(period: p);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    Text('Portal Kasir: ${widget.user.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Penerimaan unit walk-in, pantau antrean kasir, konfirmasi jadwal, dan serah terima unit.', style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: ReparoTheme.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusControl))),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Buat Booking Baru', style: TextStyle(fontSize: 13)),
                    onPressed: () => widget.onNavigate('cashier_booking'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Segarkan', style: TextStyle(fontSize: 13)),
                    onPressed: _loadAll,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminStatsBar(stats: _stats, currentPeriod: _statsPeriod, onPeriodChanged: _onPeriodChanged),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua Antrean Kasir'),
                selected: _currentTab == 'all',
                onSelected: (val) { if (val && _currentTab != 'all') { setState(() => _currentTab = 'all'); _loadAll(); } },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.public, size: 14),
                label: const Text('Antrean Global'),
                selected: _currentTab == 'global',
                onSelected: (val) { if (val && _currentTab != 'global') { setState(() => _currentTab = 'global'); _loadAll(); } },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildOrderRow(_orders[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: ReparoTheme.surface, borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel), border: Border.all(color: ReparoTheme.border)),
      child: Center(
        child: Text(
          _currentTab == 'global' ? 'Tidak ada antrean pesanan di pool global saat ini.' : 'Tidak ada antrean pesanan kasir aktif saat ini.',
          style: const TextStyle(color: ReparoTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> o) {
    final status = o['status'] as String? ?? 'BOOKED';
    final orderId = o['id'].toString();
    final tech = o['technician'] as Map<String, dynamic>?;
    final inv = o['invoice'] as Map<String, dynamic>?;
    final deviceStr = (o['device_name'] as String?)?.isNotEmpty == true ? o['device_name'] : '${o['device']?['brand'] ?? ''} ${o['device']?['model'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ReparoTheme.surface, borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel), border: Border.all(color: ReparoTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(o['public_reference'] ?? '', style: const TextStyle(fontFamily: ReparoTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 8),
                  StatusBadge(label: status, variant: _getVariant(status)),
                ],
              ),
              Text(
                tech != null ? 'Teknisi: ${tech['name']}' : 'Antrean Global (Belum Diambil)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tech != null ? ReparoTheme.accent : ReparoTheme.statusWarning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pelanggan: ${o['customer']?['name'] ?? '-'} • Perangkat: $deviceStr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Jadwal: ${o['confirmed_arrival_date'] ?? o['preferred_arrival_date'] ?? 'Belum ada jadwal'} ${o['confirmed_arrival_date'] != null ? "(Terkonfirmasi)" : "(Preferensi)"}', style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
          if (inv != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Invoice: ${inv['invoice_number']} (Rp ${inv['amount']} - ${inv['status']})', style: const TextStyle(fontSize: 12, fontFamily: ReparoTheme.fontMono, color: ReparoTheme.accent)),
                if (inv['status'] == 'OPEN') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => CashierOrderDialogs.showCorrectionDialog(context, inv['id'].toString(), double.tryParse(inv['amount'].toString()) ?? 0, widget.cashierService, _loadAll),
                    child: const Text('Koreksi Nilai', style: TextStyle(fontSize: 11, color: ReparoTheme.accent, decoration: TextDecoration.underline)),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: ReparoTheme.rule),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_calendar, size: 14),
                label: const Text('Konfirmasi Jadwal', style: TextStyle(fontSize: 12)),
                onPressed: () => CashierOrderDialogs.showScheduleDialog(context, orderId, widget.cashierService, _loadAll),
              ),
              if (status == 'READY' && inv != null && inv['status'] == 'PAID')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: ReparoTheme.statusSuccess, foregroundColor: Colors.white),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Serah Terima Fisik', style: TextStyle(fontSize: 12)),
                  onPressed: () => CashierOrderDialogs.showHandoverDialog(context, orderId, o['customer']?['name'] ?? 'Pelanggan', o['lock_version'] is int ? o['lock_version'] as int : null, widget.cashierService, _loadAll),
                ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeVariant _getVariant(String status) {
    if (status == 'READY' || status == 'COMPLETED') return BadgeVariant.success;
    if (status == 'IN_REPAIR' || status == 'QC') return BadgeVariant.warning;
    return status == 'CANCELLED' ? BadgeVariant.error : BadgeVariant.neutral;
  }
}
