import 'package:flutter/material.dart';
import '../services/technician_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';
import 'technician_order_dialogs.dart';

class TechnicianOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final TechnicianService service;
  final VoidCallback onRefresh;

  const TechnicianOrderCard({
    super.key,
    required this.order,
    required this.service,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'BOOKED';
    final id = order['id'].toString();
    final ref = order['public_reference'] as String? ?? '';
    final custName = order['customer']?['name'] ?? 'Pelanggan';
    final brand = order['device']?['brand'] ?? '';
    final model = order['device']?['model'] ?? '';
    final diag = order['diagnosis']?['customer_safe_summary'] as String?;
    final notes = List<Map<String, dynamic>>.from(order['work_notes'] ?? []);
    final estimates = List<Map<String, dynamic>>.from(order['estimate_revisions'] ?? []);
    final qcs = List<Map<String, dynamic>>.from(order['qc_checks'] ?? []);
    final hasFailedQc = status == 'QC' && qcs.isNotEmpty && qcs.last['result'] == 'FAIL';

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
          Text('Keluhan: ${order['issue_description'] ?? '-'}', style: const TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: ReparoTheme.rule),
          const SizedBox(height: 16),

          // Privacy Section: Safe Diagnosis vs Internal Staff Notes
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

          // Failed QC alert if in rework
          if (hasFailedQc) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ReparoTheme.statusErrorBg,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                border: Border.all(color: ReparoTheme.statusError.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: ReparoTheme.statusError),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QC Sebelumnya Gagal: ${qcs.last['note'] ?? 'Perlu perbaikan ulang sebelum re-QC'}',
                      style: const TextStyle(fontSize: 12, color: ReparoTheme.statusError, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                    await service.startDiagnosis(id);
                    onRefresh();
                  },
                ),
              if (status == 'DIAGNOSING' || status == 'IN_REPAIR' || status == 'QC') ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Tulis Diagnosis'),
                  onPressed: () => TechnicianOrderDialogs.showDiagnosisDialog(
                    context, service, id, diag ?? '', onRefresh,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: Text(estimates.isEmpty ? 'Buat Estimasi' : 'Revisi Estimasi (${estimates.length})'),
                  onPressed: () => TechnicianOrderDialogs.showEstimateDialog(
                    context, service, id, estimates.isNotEmpty, onRefresh,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.note_add, size: 16),
                  label: const Text('Catatan Internal'),
                  onPressed: () => TechnicianOrderDialogs.showWorkNoteDialog(
                    context, service, id, onRefresh,
                  ),
                ),
              ],
              if (status == 'DIAGNOSING')
                ReparoButton(
                  label: 'Mulai Perbaikan Fisik',
                  onPressed: () async {
                    await service.startRepair(id);
                    onRefresh();
                  },
                ),
              if (status == 'IN_REPAIR')
                ReparoButton(
                  label: 'Kirim ke Tahap QC',
                  onPressed: () async {
                    await service.startQc(id);
                    onRefresh();
                  },
                ),
              if (status == 'QC')
                ReparoButton(
                  label: 'Uji Mutu (QC)',
                  isPrimary: true,
                  onPressed: () => TechnicianOrderDialogs.showQcDialog(
                    context, service, id, onRefresh,
                  ),
                ),
              if (status == 'READY')
                ReparoButton(
                  label: 'Selesaikan Serah Terima (Handover)',
                  isPrimary: true,
                  onPressed: () async {
                    final res = await service.completeHandover(id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? res['error'] ?? '')),
                      );
                      onRefresh();
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
