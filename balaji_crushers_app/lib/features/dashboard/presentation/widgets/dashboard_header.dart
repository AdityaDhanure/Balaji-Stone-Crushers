import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

// ─── Greeting Banner ───────────────────────────────────────────────────────────
class DashboardGreetingBanner extends StatelessWidget {
  const DashboardGreetingBanner({super.key});

  String get _greeting {
    final h = appNowIst().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final h = appNowIst().hour;
    if (h < 12) return '☀️';
    if (h < 17) return '⚡';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2E5D9F), Color(0xFF1A5276)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A5F).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        // Decorative bubbles
        Positioned(top: -20, right: 30, child: _Bubble(80, 0.06)),
        Positioned(bottom: -30, right: -10, child: _Bubble(100, 0.04)),
        Positioned(top: 20, right: 150, child: _Bubble(40, 0.05)),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('$_greeting $_greetingEmoji', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              const Text('Balaji Crushers · Management System', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 14),
              Row(children: [
                _PillBadge(icon: Icons.calendar_month_rounded, label: DateFormat('dd MMM yyyy').format(appNowIst())),
                const SizedBox(width: 8),
                _PillBadge(icon: Icons.access_time_rounded, label: DateFormat('hh:mm a').format(appNowIst())),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
              child: const Icon(Icons.factory_rounded, color: Colors.white, size: 34),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size; final double opacity;
  const _Bubble(this.size, this.opacity);
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)));
}

class _PillBadge extends StatelessWidget {
  final IconData icon; final String label;
  const _PillBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 12),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final IconData? trendIcon;
  final Color? trendColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trendIcon,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          if (trendIcon != null)
            Icon(trendIcon, color: trendColor ?? AppColors.success, size: 16),
        ]),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  const DashboardSectionHeader({super.key, required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    if (icon != null) ...[
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
      const SizedBox(width: 10),
    ],
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  ]);
}
