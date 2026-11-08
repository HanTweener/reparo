import 'package:flutter/material.dart';
import '../theme/reparo_theme.dart';

class AdminStatsBar extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String currentPeriod;
  final ValueChanged<String> onPeriodChanged;

  const AdminStatsBar({
    super.key,
    required this.stats,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Text('Statistik Antrean', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 4,
                children: [
                  _buildPeriodChip('Hari Ini', 'day'),
                  _buildPeriodChip('Minggu Ini', 'week'),
                  _buildPeriodChip('Bulan Ini', 'month'),
                  _buildPeriodChip('Semua', 'all'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Antrean Masuk', stats['incoming'] ?? 0, Icons.inbox, ReparoTheme.accent),
              const SizedBox(width: 12),
              _buildStatCard('Sedang Dikerjakan', stats['in_progress'] ?? 0, Icons.build, ReparoTheme.statusWarning),
              const SizedBox(width: 12),
              _buildStatCard('Sudah Selesai', stats['completed'] ?? 0, Icons.check_circle, ReparoTheme.statusSuccess),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String p) {
    final sel = currentPeriod == p;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : ReparoTheme.textPrimary)),
      selected: sel,
      selectedColor: ReparoTheme.accent,
      onSelected: (_) => onPeriodChanged(p),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildStatCard(String title, dynamic count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ReparoTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
          border: Border.all(color: ReparoTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, size: 16, color: color)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: ReparoTheme.textMuted)),
                Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

