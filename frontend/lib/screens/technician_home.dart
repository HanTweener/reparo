import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/technician_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';
import 'technician_order_dialogs.dart';

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
                    Text('Tugas Teknisi — ${widget.user.name}',
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
            ..._orders.map((o) => _buildOrderCard(o)),
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

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final status = o['status'] as String? ?? 'BOOKED';
    final id = o['id'].toString();
    final ref = o['public_reference'] as String? ?? '';
    final custName = o['customer']?['name'] ?? 'Pelanggan';
    final brand = o['device']?['brand'] ?? '';
    final model = o['device']?['model'] ?? '';
    final diag = o['diagnosis']?['customer_safe_summary'] as String?;
    final notes = List<Map<String, dynamic>>.from(o['work_notes'] ?? []);
    final estimates = List<Map<String, dynamic>>.from(o['estimate_revisions'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ReparoTheme.surface,
        borderRadius: BorderRadius.circular(ReparoTheme.radiusPanel),
        border: Border.all(color: ReparoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(ref, style: const TextStyle(fontFamily: ReparoTheme.fontMono, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  StatusBadge(label: status, variant: _getBadgeVariant(status)),
                ],
              ),
              Text('Pelanggan: $custName', style: const TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Perangkat: $brand $model', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Keluhan: ${o['issue_description'] ?? '-'}', style: const TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: ReparoTheme.rule),
          const SizedBox(height: 16),

          // Privacy distinction: Diagnosis vs Work Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ReparoTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                    border: Border.all(color: ReparoTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.visibility, size: 14, color: ReparoTheme.accent),
                          SizedBox(width: 6),
                          Text('Diagnosis Aman Pelanggan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(diag ?? 'Belum ada diagnosis yang dicatat.', style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ReparoTheme.statusWarningBg,
                    borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                    border: Border.all(color: ReparoTheme.statusWarning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: ReparoTheme.statusWarning),
                              SizedBox(width: 6),
                              Text('Catatan Internal Staf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ReparoTheme.statusWarning)),
                            ],
                          ),
                          Text('${notes.length} Catatan', style: const TextStyle(fontSize: 11, color: ReparoTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notes.isNotEmpty ? notes.last['note_text'] : 'Belum ada catatan internal.',
                        style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Toolbar
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (status == 'BOOKED')
                ReparoButton(
                  label: 'Mulai Diagnosis',
                  onPressed: () async {
                    await _service.startDiagnosis(id);
                    _loadOrders();
                  },
                ),
              if (status == 'DIAGNOSING' || status == 'IN_REPAIR' || status == 'QC') ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Tulis Diagnosis'),
                  onPressed: () => TechnicianOrderDialogs.showDiagnosisDialog(
                    context, _service, id, diag ?? '', _loadOrders,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: Text(estimates.isEmpty ? 'Buat Estimasi' : 'Revisi Estimasi (${estimates.length})'),
                  onPressed: () => TechnicianOrderDialogs.showEstimateDialog(
                    context, _service, id, estimates.isNotEmpty, _loadOrders,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.note_add, size: 16),
                  label: const Text('Catatan Internal'),
                  onPressed: () => TechnicianOrderDialogs.showWorkNoteDialog(
                    context, _service, id, _loadOrders,
                  ),
                ),
              ],
              if (status == 'DIAGNOSING')
                ReparoButton(
                  label: 'Mulai Perbaikan Fisik',
                  onPressed: () async {
                    await _service.startRepair(id);
                    _loadOrders();
                  },
                ),
              if (status == 'IN_REPAIR')
                ReparoButton(
                  label: 'Kirim ke Tahap QC',
                  onPressed: () async {
                    await _service.startQc(id);
                    _loadOrders();
                  },
                ),
              if (status == 'QC')
                ReparoButton(
                  label: 'Uji Mutu (QC)',
                  isPrimary: true,
                  onPressed: () => TechnicianOrderDialogs.showQcDialog(
                    context, _service, id, _loadOrders,
                  ),
                ),
              if (status == 'READY')
                ReparoButton(
                  label: 'Selesaikan Serah Terima (Handover)',
                  isPrimary: true,
                  onPressed: () async {
                    final res = await _service.completeHandover(id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? res['error'] ?? '')),
                      );
                      _loadOrders();
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeVariant _getBadgeVariant(String status) {
    switch (status) {
      case 'BOOKED': return BadgeVariant.neutral;
      case 'DIAGNOSING': return BadgeVariant.neutral;
      case 'IN_REPAIR': return BadgeVariant.warning;
      case 'QC': return BadgeVariant.warning;
      case 'READY': return BadgeVariant.success;
      case 'COMPLETED': return BadgeVariant.success;
      case 'CANCELLED': return BadgeVariant.error;
      default: return BadgeVariant.neutral;
    }
  }
}
