import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/dashboard_provider.dart';
import '../../../blast/presentation/providers/blast_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardProvider);
    final blastState = ref.watch(blastProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final billingState = ref.watch(billingProvider);
    final isSmall = MediaQuery.of(context).size.width < 900;
    final padding = isSmall ? 14.0 : 22.0;

    final recentActivity = _buildAllActivity(blastState, vehicleState, billingState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.read(dashboardProvider.notifier).loadAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Hero banner ──────────────────────────────────────────────────
            const DashboardGreetingBanner(),
            const SizedBox(height: 18),

            // ── KPI stats ────────────────────────────────────────────────────
            stats.isLoading
                ? _buildLoadingStats(isSmall)
                : isSmall
                    ? _buildStatsMobile(stats)
                    : _buildStatsDesktop(stats),
            const SizedBox(height: 18),

            // ── Quick actions ─────────────────────────────────────────────────
            const DashboardSectionHeader(title: 'Quick Actions', subtitle: 'Tap to navigate', icon: Icons.flash_on_rounded),
            const SizedBox(height: 12),
            const DashboardQuickActions(),
            const SizedBox(height: 20),

            // ── All Modules ───────────────────────────────────────────────────
            const DashboardSectionHeader(title: 'All Modules', subtitle: 'Full access to every section', icon: Icons.grid_view_rounded),
            const SizedBox(height: 12),
            DashboardModulesGrid(isSmallScreen: isSmall),
            const SizedBox(height: 20),

            // ── Recent Activity ───────────────────────────────────────────────
            DashboardSectionHeader(
              title: 'Recent Activity',
              subtitle: '${recentActivity.length} events across all modules',
              icon: Icons.timeline_rounded,
            ),
            const SizedBox(height: 12),
            DashboardActivityFeed(items: recentActivity),
            const SizedBox(height: 12),
            const DashboardSystemStatus(),
          ]),
        ),
      ),
    );
  }

  // ─── Merge activity from all loaded providers ─────────────────────────────
  List<ActivityItem> _buildAllActivity(BlastState blastState, VehicleState vehicleState, BillingState billingState) {
    final items = <_RawActivity>[];

    // ── Blasts ──────────────────────────────────────────────────────────────
    for (final b in blastState.blasts.take(5)) {
      final dt = _parseDate(b['created_at']?.toString());
      final isActive = b['status'] == 'active';
      items.add(_RawActivity(
        title: 'Blast #${b['blast_number']} — ${(b['blast_type'] ?? '').toString().toUpperCase()}',
        subtitle: '${b['feet'] ?? 0} ft · ${isActive ? 'Active' : 'Completed'}',
        icon: Icons.bolt_rounded,
        color: AppColors.accent,
        time: dt,
      ));
    }

    // ── Vehicles ─────────────────────────────────────────────────────────────
    for (final v in vehicleState.vehicles.take(4)) {
      final dt = _parseDate(v['created_at']?.toString());
      items.add(_RawActivity(
        title: 'Vehicle: ${v['vehicle_number'] ?? '—'}',
        subtitle: '${v['vehicle_type'] ?? '—'} · ${v['status'] ?? 'active'}',
        icon: Icons.local_shipping_rounded,
        color: AppColors.info,
        time: dt,
      ));
    }

    // ── Billing invoices ──────────────────────────────────────────────────────
    for (final inv in billingState.invoices.take(5)) {
      final dt = _parseDate(inv.invoiceDate);
      final statusColor = inv.status == 'paid' ? AppColors.success : inv.status == 'partial' ? AppColors.warning : AppColors.error;
      items.add(_RawActivity(
        title: 'Invoice ${inv.invoiceNumber}',
        subtitle: '${inv.customerName ?? '—'} · ₹${NumberFormat.compact().format(inv.totalAmount)} · ${inv.statusDisplay}',
        icon: Icons.receipt_long_rounded,
        color: statusColor,
        time: dt,
      ));
    }

    // ── Sort all by time desc & take top 12 ────────────────────────────────
    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(12).map((r) => ActivityItem(
      title: r.title,
      subtitle: r.subtitle,
      icon: r.icon,
      color: r.color,
      time: r.time,
    )).toList();
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime(2020);
    return appParseIstDateTime(raw) ?? DateTime(2020);
  }

  // ── Loading shimmer ────────────────────────────────────────────────────────
  Widget _buildLoadingStats(bool isSmall) => isSmall
      ? Column(children: [
          Row(children: [_shimmer(), const SizedBox(width: 10), _shimmer()]),
          const SizedBox(height: 10),
          Row(children: [_shimmer(), const SizedBox(width: 10), _shimmer()]),
        ])
      : Row(children: [
          _shimmer(), const SizedBox(width: 12),
          _shimmer(), const SizedBox(width: 12),
          _shimmer(), const SizedBox(width: 12),
          _shimmer(),
        ]);

  Widget _shimmer() => Expanded(child: Container(height: 100, decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16))));

  // ── Stats desktop ─────────────────────────────────────────────────────────
  Widget _buildStatsDesktop(DashboardStats s) => Row(children: [
    Expanded(child: DashboardStatCard(title: 'Active Blasts', value: '${s.activeBlasts}', subtitle: 'Currently running', icon: Icons.bolt_rounded, color: AppColors.accent, trendIcon: Icons.trending_up_rounded, trendColor: AppColors.success)),
    const SizedBox(width: 12),
    Expanded(child: DashboardStatCard(title: 'Total Vehicles', value: '${s.totalVehicles}', subtitle: 'Fleet registered', icon: Icons.local_shipping_rounded, color: AppColors.info, trendIcon: Icons.trending_up_rounded, trendColor: AppColors.success)),
    const SizedBox(width: 12),
    Expanded(child: DashboardStatCard(title: 'Customers', value: '${s.totalCustomers}', subtitle: 'Active accounts', icon: Icons.people_rounded, color: AppColors.success, trendIcon: Icons.trending_up_rounded, trendColor: AppColors.success)),
    const SizedBox(width: 12),
    Expanded(child: DashboardStatCard(title: 'Pending Bills', value: '₹${NumberFormat.compact().format(s.pendingBills)}', subtitle: 'To collect', icon: Icons.currency_rupee_rounded, color: AppColors.error, trendIcon: Icons.warning_amber_rounded, trendColor: AppColors.warning)),
  ]);

  // ── Stats mobile ──────────────────────────────────────────────────────────
  Widget _buildStatsMobile(DashboardStats s) => Column(children: [
    Row(children: [
      Expanded(child: DashboardStatCard(title: 'Active Blasts', value: '${s.activeBlasts}', subtitle: 'Running', icon: Icons.bolt_rounded, color: AppColors.accent)),
      const SizedBox(width: 10),
      Expanded(child: DashboardStatCard(title: 'Vehicles', value: '${s.totalVehicles}', subtitle: 'Fleet', icon: Icons.local_shipping_rounded, color: AppColors.info)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: DashboardStatCard(title: 'Customers', value: '${s.totalCustomers}', subtitle: 'Accounts', icon: Icons.people_rounded, color: AppColors.success)),
      const SizedBox(width: 10),
      Expanded(child: DashboardStatCard(title: 'Pending Bills', value: '₹${NumberFormat.compact().format(s.pendingBills)}', subtitle: 'To collect', icon: Icons.currency_rupee_rounded, color: AppColors.error)),
    ]),
  ]);
}

// ─── Internal model for merging ────────────────────────────────────────────────
class _RawActivity {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime time;
  const _RawActivity({required this.title, required this.subtitle, required this.icon, required this.color, required this.time});
}
