import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

const _kAccent = Color(0xFFE67E22);
const _kAccentDark = Color(0xFFD35400);

// ─── Active Blast Hero Card ────────────────────────────────────────────────────
class ActiveBlastCard extends StatelessWidget {
  final dynamic blast;
  final bool isCompleted;
  final bool isSmallScreen;
  final VoidCallback onViewDetails;
  final VoidCallback onToggleStatus;

  const ActiveBlastCard({
    super.key,
    required this.blast,
    required this.isCompleted,
    required this.isSmallScreen,
    required this.onViewDetails,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final dt = appParseIstDate(blast['blast_date']);
    final dateLabel = dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—';
    final feet = blast['feet']?.toString() ?? '0';
    final trips = blast['total_trips']?.toString() ?? '0';
    final expenses = double.tryParse(blast['total_expenses']?.toString() ?? '0') ?? 0;
    final blastType = (blast['blast_type'] ?? '').toString().toUpperCase();
    final blastNum = blast['blast_number']?.toString() ?? '—';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [const Color(0xFF555566), const Color(0xFF2E2E3D)]
              : [const Color(0xFFE67E22), const Color(0xFFC0392B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (isCompleted ? Colors.grey : _kAccent).withValues(alpha: 0.45),
          blurRadius: 18, offset: const Offset(0, 8),
        )],
      ),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(top: -30, right: -20, child: _bubble(130, 0.06)),
        Positioned(bottom: -40, right: 70, child: _bubble(90, 0.04)),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StatusBadge(isCompleted: isCompleted),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Blast #$blastNum', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(blastType, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, letterSpacing: 0.6)),
              ]),
            ]),
            const SizedBox(height: 16),
            // Stats row
            Row(children: [
              _StatBox(icon: Icons.calendar_today_rounded, label: 'Date', value: dateLabel),
              const SizedBox(width: 8),
              _StatBox(icon: Icons.straighten_rounded, label: 'Feet', value: '$feet ft'),
              const SizedBox(width: 8),
              _StatBox(icon: Icons.route_rounded, label: 'Trips', value: trips),
              const SizedBox(width: 8),
              _StatBox(icon: Icons.account_balance_wallet_rounded, label: 'Expenses', value: '₹${NumberFormat.compact().format(expenses)}'),
            ]),
            const SizedBox(height: 16),
            // Actions
            Row(children: [
              Expanded(child: _GlassBtn(icon: Icons.visibility_rounded, label: 'View Details', onTap: onViewDetails)),
              const SizedBox(width: 10),
              Expanded(child: _GlassBtn(
                icon: isCompleted ? Icons.refresh_rounded : Icons.check_circle_rounded,
                label: isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                onTap: onToggleStatus,
              )),
            ]),
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
  final bool isCompleted;
  const _StatusBadge({required this.isCompleted});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? Colors.grey.shade400 : Colors.greenAccent,
          boxShadow: isCompleted ? null : [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.7), blurRadius: 5)],
        ),
      ),
      const SizedBox(width: 6),
      Text(isCompleted ? 'COMPLETED' : 'ACTIVE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    ]),
  );
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox({required this.icon, required this.label, required this.value});
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

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}

// ─── No Active Blast ───────────────────────────────────────────────────────────
class NoActiveBlastCard extends StatelessWidget {
  final bool isSmallScreen;
  final VoidCallback onStartBlast;
  const NoActiveBlastCard({super.key, required this.isSmallScreen, required this.onStartBlast});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kAccent.withValues(alpha: 0.35), width: 1.5),
      boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.bolt_rounded, color: _kAccent, size: 28),
      ),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('No Active Blast', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        SizedBox(height: 3),
        Text('Start a new blast to begin tracking', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ])),
      const SizedBox(width: 10),
      _NewBlastBtn(isSmall: isSmallScreen, onTap: onStartBlast),
    ]),
  );
}

class _NewBlastBtn extends StatelessWidget {
  final bool isSmall;
  final VoidCallback onTap;
  const _NewBlastBtn({required this.isSmall, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_kAccent, _kAccentDark]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, color: Colors.white, size: 15),
        const SizedBox(width: 5),
        Text(isSmall ? 'Start' : 'New Blast', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

// ─── Blast List Item ───────────────────────────────────────────────────────────
class BlastListItem extends StatelessWidget {
  final dynamic blast;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const BlastListItem({super.key, required this.blast, required this.isSmallScreen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = blast['status'] == 'active';
    final dt = appParseIstDate(blast['blast_date']);
    final dateLabel = dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—';
    final trips = int.tryParse(blast['total_trips']?.toString() ?? '0') ?? 0;
    final expenses = double.tryParse(blast['total_expenses']?.toString() ?? '0') ?? 0;
    final blastType = (blast['blast_type'] ?? '').toString();
    final feet = blast['feet']?.toString() ?? '0';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? _kAccent.withValues(alpha: 0.35) : AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Left accent bar
          Container(
            width: 4, height: 68,
            decoration: BoxDecoration(
              color: isActive ? _kAccent : AppColors.border,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isActive ? _kAccent.withValues(alpha: 0.1) : AppColors.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isActive ? _kAccent.withValues(alpha: 0.2) : AppColors.border),
            ),
            child: Icon(Icons.bolt_rounded, color: isActive ? _kAccent : AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Blast #${blast['blast_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5)),
                  child: Text(blastType.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kAccent, letterSpacing: 0.3)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('$dateLabel · $feet ft', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          )),
          // Trailing
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$trips trips', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary)),
              Text('₹${NumberFormat.compact().format(expenses)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18)),
        ]),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class BlastEmptyState extends StatelessWidget {
  const BlastEmptyState({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.bolt_outlined, size: 48, color: _kAccent.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 16),
        const Text('No blasts recorded', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Tap the + button to create a new blast', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ),
  );
}
