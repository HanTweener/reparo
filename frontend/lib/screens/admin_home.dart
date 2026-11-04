import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';
import 'admin_order_dialogs.dart';

class AdminHome extends StatefulWidget {
  final AuthUser user;
  final ApiService apiService;
  final RepairService repairService;
  final ValueChanged<String> onNavigate;

  const AdminHome({
    super.key,
    required this.user,
    required this.apiService,
    required this.repairService,
    required this.onNavigate,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _paymentService = PaymentService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final list = await widget.repairService.getAdminOrders();
    if (mounted) setState(() { _orders = list; _isLoading = false; });
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
                    Text('Antrean Operasional: ${widget.user.name}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Kelola penjadwalan kedatangan, penugasan teknisi, dan permohonan pembatalan',
                        style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.people_outline, size: 16),
                    label: const Text('Kelola Staf', style: TextStyle(fontSize: 13)),
                    onPressed: () => widget.onNavigate('staff'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Segarkan', style: TextStyle(fontSize: 13)),
                    onPressed: _loadQueue,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
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
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: const Center(
        child: Text('Tidak ada antrean pesanan aktif saat ini.', style: TextStyle(color: ReparoTheme.textMuted)),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> o) {
    final status = o['status'] as String? ?? 'BOOKED';
    final orderId = o['id'].toString();
    final hasCancel = o['has_pending_cancellation'] == true;
    final tech = o['technician'] as Map<String, dynamic>?;
    final inv = o['invoice'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: hasCancel ? ReparoTheme.statusError.withValues(alpha: 0.5) : ReparoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(o['public_reference'] ?? '',
                      style: const TextStyle(fontFamily: ReparoTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 8),
                  StatusBadge(label: status, variant: _getVariant(status)),
                  if (hasCancel) ...[
                    const SizedBox(width: 8),
                    const StatusBadge(label: 'Permohonan Batal', variant: BadgeVariant.error),
                  ],
                ],
              ),
              Text(
                tech != null ? 'Teknisi: ${tech['name']}' : 'Belum Ditugaskan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tech != null ? ReparoTheme.accent : ReparoTheme.statusWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pelanggan: ${o['customer']?['name'] ?? '-'} • Perangkat: ${o['device']?['brand'] ?? ''} ${o['device']?['model'] ?? ''}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadwal: ${o['confirmed_arrival_date'] ?? o['preferred_arrival_date'] ?? 'Belum ada jadwal'} ' +
                (o['confirmed_arrival_date'] != null ? '(Terkonfirmasi)' : '(Preferensi Pelanggan)'),
            style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted),
          ),
          if (inv != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Invoice: ${inv['invoice_number']} (Rp ${inv['amount']} - ${inv['status']})',
                    style: const TextStyle(fontSize: 12, fontFamily: ReparoTheme.fontMono, color: ReparoTheme.accent)),
                if (inv['status'] == 'OPEN') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => AdminOrderDialogs.showInvoiceCorrectionDialog(
                      context, inv['id'].toString(), double.tryParse(inv['amount'].toString()) ?? 0, _paymentService, _loadQueue,
                    ),
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
                icon: const Icon(Icons.person_add, size: 14),
                label: Text(tech != null ? 'Ganti Teknisi' : 'Tugaskan Teknisi', style: const TextStyle(fontSize: 12)),
                onPressed: () => AdminOrderDialogs.showAssignDialog(context, orderId, widget.apiService, widget.repairService, _loadQueue),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_calendar, size: 14),
                label: const Text('Konfirmasi Jadwal', style: TextStyle(fontSize: 12)),
                onPressed: () => AdminOrderDialogs.showConfirmScheduleDialog(context, orderId, widget.repairService, _loadQueue),
              ),
              if (hasCancel)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: ReparoTheme.statusError, foregroundColor: Colors.white),
                  icon: const Icon(Icons.warning, size: 14),
                  label: const Text('Tinjau Pembatalan', style: TextStyle(fontSize: 12)),
                  onPressed: () => AdminOrderDialogs.showCancellationDialog(context, orderId, widget.repairService, _loadQueue),
                ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeVariant _getVariant(String status) {
    switch (status) {
      case 'CANCELLED': return BadgeVariant.error;
      case 'READY': return BadgeVariant.success;
      case 'COMPLETED': return BadgeVariant.success;
      case 'DIAGNOSING': return BadgeVariant.neutral;
      case 'IN_REPAIR': return BadgeVariant.warning;
      case 'QC': return BadgeVariant.warning;
      default: return BadgeVariant.neutral;
    }
  }
}
