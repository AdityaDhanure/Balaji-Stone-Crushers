import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

// ─── Activity Item model ───────────────────────────────────────────────────────
class ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime time;
  const ActivityItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.time});
}

// ─── Recent Activity Feed ──────────────────────────────────────────────────────
class DashboardActivityFeed extends StatelessWidget {
  final List<ActivityItem> items;
  const DashboardActivityFeed({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timeline_rounded, size: 40, color: AppColors.border),
          SizedBox(height: 10),
          Text('No recent activity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('Activity will appear here as you use the system', style: TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ])),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return _ActivityRow(item: e.value, isLast: isLast);
      }).toList()),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  final bool isLast;
  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: item.color.withValues(alpha: 0.2))),
          child: Icon(item.icon, color: item.color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
          Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(_timeAgo(item.time), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ),
    if (!isLast) Divider(color: AppColors.border, height: 1, indent: 62),
  ]);

  String _timeAgo(DateTime dt) {
    final diff = appNowIst().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dt);
  }
}

// ─── System Status Row ─────────────────────────────────────────────────────────
class DashboardSystemStatus extends StatelessWidget {
  const DashboardSystemStatus({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: AppColors.success,
          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 6)],
        ),
      ),
      const SizedBox(width: 10),
      const Text('All systems operational', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
      const Spacer(),
      Text('v2.0.0', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
    ]),
  );
}
