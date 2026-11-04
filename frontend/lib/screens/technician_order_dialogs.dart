import 'package:flutter/material.dart';
import '../services/technician_service.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';

class TechnicianOrderDialogs {
  static void showDiagnosisDialog(
    BuildContext context,
    TechnicianService service,
    String orderId,
    String currentSummary,
    VoidCallback onSuccess,
  ) {
    final controller = TextEditingController(text: currentSummary);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ringkasan Diagnosis (Aman untuk Pelanggan)'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Contoh: Heatsink tersumbat debu, thermal paste kering...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan Diagnosis',
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final ok = await service.saveDiagnosis(orderId, controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (ok) onSuccess();
            },
          ),
        ],
      ),
    );
  }

  static void showEstimateDialog(
    BuildContext context,
    TechnicianService service,
    String orderId,
    bool isRevision,
    VoidCallback onSuccess,
  ) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRevision ? 'Revisi Estimasi Biaya' : 'Buat Estimasi Biaya Awal'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Estimasi (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
              ),
              if (isRevision) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Perubahan Biaya (Wajib)',
                    hintText: 'Contoh: Ditemukan korosi tambahan pada jalur daya',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan Estimasi',
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''));
              if (amt == null || amt <= 0) return;
              if (isRevision && reasonCtrl.text.trim().isEmpty) return;

              final res = await service.addEstimate(
                orderId,
                amt,
                isRevision ? reasonCtrl.text.trim() : null,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (res['success'] == true) {
                onSuccess();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['error'] ?? 'Gagal menyimpan estimasi')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static void showWorkNoteDialog(
    BuildContext context,
    TechnicianService service,
    String orderId,
    VoidCallback onSuccess,
  ) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Catatan Internal (Hanya Staf)'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Catatan teknis internal yang dirahasiakan dari pelanggan...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ReparoButton(
            label: 'Simpan Catatan',
            onPressed: () async {
              if (noteCtrl.text.trim().isEmpty) return;
              final ok = await service.addWorkNote(orderId, noteCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (ok) onSuccess();
            },
          ),
        ],
      ),
    );
  }

  static void showQcDialog(
    BuildContext context,
    TechnicianService service,
    String orderId,
    VoidCallback onSuccess,
  ) {
    String qcResult = 'PASS';
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Pemeriksaan Kontrol Kualitas (QC)'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hasil Pengujian Mutu:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Lolos (PASS)'),
                      selected: qcResult == 'PASS',
                      onSelected: (val) => setModalState(() => qcResult = 'PASS'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Gagal (FAIL)'),
                      selected: qcResult == 'FAIL',
                      onSelected: (val) => setModalState(() => qcResult = 'FAIL'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Hasil Pemeriksaan',
                    hintText: 'Contoh: Suhu stresstest 65C normal, audio jernih',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ReparoButton(
              label: 'Kirim Hasil QC',
              onPressed: () async {
                final res = await service.submitQcCheck(orderId, qcResult, noteCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (res['success'] == true) onSuccess();
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showHandoverDialog(
    BuildContext context,
    TechnicianService service,
    String orderId,
    String customerName,
    VoidCallback onSuccess, {
    int? expectedVersion,
  }) {
    final nameCtrl = TextEditingController(text: customerName);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Serah Terima Perangkat'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pastikan pembayaran telah diverifikasi lunas dan kondisi fisik perangkat sudah diperiksa bersama pelanggan sebelum serah terima.',
                style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Penerima Perangkat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Serah Terima (Opsional)',
                  hintText: 'Contoh: Perangkat diterima lengkap beserta charger dan box',
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
              final res = await service.completeHandover(
                orderId,
                recipientName: nameCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
                expectedVersion: expectedVersion,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (res['success'] == true) {
                onSuccess();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['error'] ?? 'Serah terima gagal.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
