import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/repair_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';

class AdminOrderDialogs {
  static void showAssignDialog(
    BuildContext context,
    String orderId,
    ApiService apiService,
    RepairService repairService,
    VoidCallback onSuccess,
  ) async {
    final staff = await apiService.getStaffList();
    final technicians = staff.where((s) => s.isTechnician && s.isActive).toList();
    if (!context.mounted) return;

    if (technicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada teknisi aktif. Silakan tambahkan staf teknisi terlebih dahulu.')),
      );
      return;
    }

    String selectedTechId = technicians.first.id;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ReparoTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet)),
          title: const Text('Tugaskan Teknisi Perbaikan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedTechId,
                decoration: const InputDecoration(labelText: 'Pilih Teknisi'),
                items: technicians
                    .map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.email})')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedTechId = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Catatan Penugasan (Opsional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ReparoButton(
              label: 'Simpan Penugasan',
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await repairService.assignTechnician(orderId, selectedTechId, reasonCtrl.text.trim());
                if (ok) onSuccess();
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showConfirmScheduleDialog(
    BuildContext context,
    String orderId,
    RepairService repairService,
    VoidCallback onSuccess,
  ) {
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0]);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ReparoTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet)),
        title: const Text('Konfirmasi Tanggal Kedatangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tentukan tanggal kedatangan terkonfirmasi untuk perbaikan perangkat ini:',
                style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(labelText: 'Tanggal Konfirmasi (YYYY-MM-DD)', hintText: '2026-11-06'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Konfirmasi Jadwal',
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await repairService.confirmSchedule(orderId, dateCtrl.text.trim());
              if (ok) onSuccess();
            },
          ),
        ],
      ),
    );
  }

  static void showCancellationDialog(
    BuildContext context,
    String orderId,
    RepairService repairService,
    VoidCallback onSuccess,
  ) {
    String decision = 'CONFIRMED';
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ReparoTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet)),
          title: const Text('Tinjau Permohonan Pembatalan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih keputusan pembatalan pesanan pra-diagnosis:',
                  style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Setujui (Batal)'),
                    selected: decision == 'CONFIRMED',
                    onSelected: (val) => setDialogState(() => decision = 'CONFIRMED'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Tolak (Lanjut)'),
                    selected: decision == 'DENIED',
                    onSelected: (val) => setDialogState(() => decision = 'DENIED'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Alasan Keputusan Admin (Opsional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
            ReparoButton(
              label: 'Kirim Keputusan',
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await repairService.decideCancellation(orderId, decision, reasonCtrl.text.trim());
                if (ok) onSuccess();
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showInvoiceCorrectionDialog(
    BuildContext context,
    String invoiceId,
    double currentAmount,
    PaymentService paymentService,
    VoidCallback onSuccess,
  ) {
    final amtCtrl = TextEditingController(text: currentAmount.toStringAsFixed(0));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ReparoTheme.surface,
        title: const Text('Koreksi Nilai Invoice (Audit Admin)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal Baru (Rp)', prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Alasan Koreksi (Wajib Diisi)', hintText: 'Contoh: Diskon khusus'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan Koreksi',
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text);
              if (amt == null || reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final res = await paymentService.correctInvoice(invoiceId, amt, reasonCtrl.text.trim());
              if (res['success'] == true) onSuccess();
            },
          ),
        ],
      ),
    );
  }

  static void showHandoverDialog(
    BuildContext context,
    String orderId,
    String customerName,
    RepairService repairService,
    VoidCallback onSuccess, {
    int? expectedVersion,
  }) {
    final nameCtrl = TextEditingController(text: customerName);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ReparoTheme.surface,
        title: const Text('Serah Terima Fisik Perangkat'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konfirmasikan bahwa pembayaran invoice telah lunas dan unit fisik diserahkan kepada pelanggan.',
                style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Penerima', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Serah Terima (Opsional)',
                  hintText: 'Contoh: Diserahkan lengkap dengan charger dan nota',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Selesaikan Serah Terima',
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await repairService.completeHandover(
                orderId,
                recipientName: nameCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
                expectedVersion: expectedVersion,
              );
              if (ok) onSuccess();
            },
          ),
        ],
      ),
    );
  }
}

