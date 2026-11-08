import 'package:flutter/material.dart';
import '../services/cashier_service.dart';
import '../widgets/reparo_button.dart';

class CashierOrderDialogs {
  static void showScheduleDialog(BuildContext context, String orderId, CashierService service, VoidCallback onSuccess) {
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toString().split(' ').first);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(label: 'Konfirmasi', onPressed: () async {
            final ok = await service.confirmSchedule(orderId, dateCtrl.text.trim());
            if (ctx.mounted) Navigator.pop(ctx);
            if (ok) onSuccess();
          }),
        ],
      ),
    );
  }

  static void showCorrectionDialog(BuildContext context, String invId, double current, CashierService service, VoidCallback onSuccess) {
    final amtCtrl = TextEditingController(text: current.toStringAsFixed(0));
    final reasonCtrl = TextEditingController(text: 'Penyesuaian kasir');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koreksi Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal Baru')),
            const SizedBox(height: 8),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Alasan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(label: 'Simpan', onPressed: () async {
            final amt = double.tryParse(amtCtrl.text.trim()) ?? current;
            final ok = await service.correctInvoice(invId, amt, reasonCtrl.text.trim());
            if (ctx.mounted) Navigator.pop(ctx);
            if (ok) onSuccess();
          }),
        ],
      ),
    );
  }

  static void showHandoverDialog(BuildContext context, String orderId, String custName, int? lockVer, CashierService service, VoidCallback onSuccess) {
    final nameCtrl = TextEditingController(text: custName);
    final notesCtrl = TextEditingController(text: 'Unit diterima dalam kondisi baik.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serah Terima Fisik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Penerima')),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(label: 'Selesai', onPressed: () async {
            final ok = await service.completeHandover(orderId, recipientName: nameCtrl.text.trim(), notes: notesCtrl.text.trim(), expectedVersion: lockVer);
            if (ctx.mounted) Navigator.pop(ctx);
            if (ok) onSuccess();
          }),
        ],
      ),
    );
  }
}

