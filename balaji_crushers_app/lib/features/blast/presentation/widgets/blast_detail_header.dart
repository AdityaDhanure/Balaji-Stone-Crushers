import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

const _kAccent = Color(0xFFE67E22);
const _kAccentDark = Color(0xFFD35400);

// ─── Gradient Hero Header ──────────────────────────────────────────────────────
class BlastDetailHeader extends StatelessWidget {
  final dynamic blast;
  final bool isActive;
  final int totalTrips;
  final double totalExpenses;
  final bool isSmallScreen;

  const BlastDetailHeader({
    super.key,
    required this.blast,
    required this.isActive,
    required this.totalTrips,
    required this.totalExpenses,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final dt = appParseIstDate(blast['blast_date']);
    final dateLabel = dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—';
    final feet = blast['feet']?.toString() ?? '0';
    final rate = blast['rate']?.toString() ?? '0';
    final drillingCost = (double.tryParse(feet) ?? 0) * (double.tryParse(rate) ?? 0);
    final blastType = (blast['blast_type'] ?? '').toString().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFFE67E22), const Color(0xFFC0392B)]
              : [const Color(0xFF555566), const Color(0xFF2E2E3D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(top: -25, right: -15, child: _bubble(110, 0.06)),
        Positioned(bottom: -35, right: 80, child: _bubble(80, 0.04)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status + type + date
            Row(children: [
              _StatusBadge(isActive: isActive),
              const Spacer(),
              Text(blastType, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(width: 10),
              Text(dateLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            // 4 stat chips
            Row(children: [
              _Chip(icon: Icons.straighten_rounded, label: 'Feet', value: '$feet ft'),
              const SizedBox(width: 8),
              _Chip(icon: Icons.price_change_rounded, label: 'Rate', value: '₹$rate/ft'),
              const SizedBox(width: 8),
              _Chip(icon: Icons.route_rounded, label: 'Trips', value: '$totalTrips'),
              const SizedBox(width: 8),
              _Chip(icon: Icons.account_balance_wallet_rounded, label: 'Expenses', value: '₹${NumberFormat.compact().format(totalExpenses)}'),
            ]),
            if (drillingCost > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(children: [
                  const Icon(Icons.construction_rounded, color: Colors.white70, size: 13),
                  const SizedBox(width: 7),
                  const Text('Drilling cost: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('₹${NumberFormat('#,##,###').format(drillingCost)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.greenAccent : Colors.grey.shade400,
          boxShadow: isActive ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.7), blurRadius: 4)] : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(isActive ? 'ACTIVE' : 'COMPLETED', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Chip({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white70, size: 12),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9)),
    ]),
  ));
}

// ─── Premium Boxed Tab Bar ─────────────────────────────────────────────────────
class BlastDetailTabBar extends StatelessWidget {
  final TabController tabController;
  const BlastDetailTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: tabController,
        labelColor: _kAccent,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(height: 42, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_shipping_rounded, size: 14), SizedBox(width: 5), Text('Trips')])),
          Tab(height: 42, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_rounded, size: 14), SizedBox(width: 5), Text('Expenses')])),
          Tab(height: 42, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.info_outline_rounded, size: 14), SizedBox(width: 5), Text('Info')])),
        ],
      ),
    );
  }
}

// ─── Premium AppBar (no delete) ────────────────────────────────────────────────
class BlastDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int blastNumber;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onReopen;
  final VoidCallback onBack;

  const BlastDetailAppBar({
    super.key,
    required this.blastNumber,
    required this.isActive,
    required this.onEdit,
    required this.onComplete,
    required this.onReopen,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive ? [_kAccent, _kAccentDark] : [const Color(0xFF555566), const Color(0xFF2E2E3D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Blast #$blastNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            // Edit button
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onEdit, borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
            // Status toggle button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: isActive ? onComplete : onReopen,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                    child: Icon(isActive ? Icons.check_circle_outline_rounded : Icons.refresh_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
