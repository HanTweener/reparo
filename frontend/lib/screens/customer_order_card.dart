import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/status_badge.dart';

class CustomerOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;
  final PaymentService paymentService;

  const CustomerOrderCard({
    super.key,
    required this.order,
    required this.onCancel,
    required this.onRefresh,
    required this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'BOOKED';
    final canCancel = status == 'BOOKED';
    final ref = order['public_reference'] ?? 'REP-TBD';
    final device = order['device'] as Map<String, dynamic>?;
    final diag = order['diagnosis']?['customer_safe_summary'] as String?;
    final estimates = List<Map<String, dynamic>>.from(order['estimate_revisions'] ?? []);
    final invoice = order['invoice'] as Map<String, dynamic>?;
    final corrections = List<Map<String, dynamic>>.from(invoice?['corrections'] ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
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
                  Text(ref, style: const TextStyle(fontFamily: ReparoTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 8),
                  StatusBadge(label: status, variant: _getVariant(status)),
                ],
              ),
              Text('Layanan: ${order['service_code'] ?? 'MAINTENANCE'}',
                  style: const TextStyle(fontSize: 12, color: ReparoTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Perangkat: ${device?['brand'] ?? ''} ${device?['model'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Keluhan: ${order['issue_description'] ?? '—'}',
              style: const TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
          const SizedBox(height: 6),
          Text(
            'Jadwal: ${order['confirmed_arrival_date'] ?? order['preferred_arrival_date'] ?? 'Menunggu konfirmasi'} ' +
                (order['confirmed_arrival_date'] != null ? '(Dikonfirmasi Admin)' : '(Preferensi Anda)'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ReparoTheme.accent),
          ),

          // Safe Diagnosis Section
          if (diag != null && diag.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ReparoTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                border: Border.all(color: ReparoTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: ReparoTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diagnosis Teknisi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(diag, style: const TextStyle(fontSize: 12, color: ReparoTheme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Estimate Revisions Section
          if (estimates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ReparoTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                border: Border.all(color: ReparoTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimasi Biaya:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Rp ${_formatMoney(estimates.last['amount'])}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ReparoTheme.accent)),
                    ],
                  ),
                  if (estimates.length > 1) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Estimasi Awal: Rp ${_formatMoney(estimates.first['amount'])} • Revisi #${estimates.length}',
                      style: const TextStyle(fontSize: 11, color: ReparoTheme.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alasan Revisi: ${estimates.last['reason'] ?? '-'}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: ReparoTheme.textPrimary),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Invoice & Payment Section
          if (invoice != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: invoice['status'] == 'PAID' ? ReparoTheme.statusSuccessBg : ReparoTheme.stateSelected,
                borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                border: Border.all(
                  color: invoice['status'] == 'PAID' ? ReparoTheme.statusSuccess.withValues(alpha: 0.3) : ReparoTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice: ${invoice['invoice_number']}',
                              style: const TextStyle(fontFamily: ReparoTheme.fontMono, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Total: Rp ${_formatMoney(invoice['amount'])}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      if (invoice['status'] == 'PAID')
                        const StatusBadge(label: 'LUNAS (PAID)', variant: BadgeVariant.success)
                      else
                        ReparoButton(
                          label: 'Bayar Sandbox',
                          isPrimary: true,
                          onPressed: () => _handleCheckout(context, invoice),
                        ),
                    ],
                  ),
                  if (corrections.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ReparoTheme.surface,
                        borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                        border: Border.all(color: ReparoTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Koreksi Biaya oleh Admin:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ReparoTheme.accent)),
                          const SizedBox(height: 2),
                          Text(
                            'Disesuaikan ke Rp ${_formatMoney(corrections.last['new_amount'])} (Semula Rp ${_formatMoney(corrections.last['previous_amount'])})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text('Alasan: ${corrections.last['reason'] ?? '-'}',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: ReparoTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: ReparoTheme.rule),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canCancel)
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ReparoTheme.statusError),
                    foregroundColor: ReparoTheme.statusError,
                  ),
                  child: const Text('Ajukan Pembatalan', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context, Map<String, dynamic> inv) async {
    final invId = inv['id'].toString();
    final res = await paymentService.createPaymentAttempt(invId);
    if (!context.mounted) return;

    if (res['success'] == true) {
      final double amt = double.tryParse(inv['amount'].toString()) ?? 0;

      // Show confirmation dialog with direct sandbox simulation option for seamless verification
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Midtrans Sandbox Checkout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Invoice: ${inv['invoice_number']}'),
              const SizedBox(height: 4),
              Text('Total Pembayaran: Rp ${_formatMoney(amt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Simulasi pembayaran sandbox Midtrans: klik tombol di bawah untuk menyimulasikan notifikasi sukses webhook settlement dari provider.',
                style: TextStyle(fontSize: 12, color: ReparoTheme.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ReparoButton(
              label: 'Konfirmasi Bayar (Simulasi Sukses)',
              onPressed: () async {
                Navigator.pop(ctx);
                await paymentService.simulatePaymentSuccess(invId);
                onRefresh();
              },
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Gagal membuat sesi pembayaran.')),
      );
    }
  }

  String _formatMoney(dynamic val) {
    if (val == null) return '0';
    final d = double.tryParse(val.toString()) ?? 0;
    return d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
