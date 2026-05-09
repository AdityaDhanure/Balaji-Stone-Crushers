import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

const _kAccent = Color(0xFFE67E22);

class BlastInfoTab extends StatelessWidget {
  final dynamic blast;
  final bool isSmallScreen;

  const BlastInfoTab({super.key, required this.blast, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final blastDt = appParseIstDate(blast['blast_date']);
    final createdDt = appParseIstDateTime(blast['created_at']);
    final status = (blast['status'] ?? '').toString();
    final isActive = status == 'active';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Status Banner ─────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive ? [_kAccent.withValues(alpha: 0.15), _kAccent.withValues(alpha: 0.04)] : [AppColors.border.withValues(alpha: 0.5), AppColors.border.withValues(alpha: 0.2)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? _kAccent.withValues(alpha: 0.25) : AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : AppColors.textSecondary,
                boxShadow: isActive ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 6)] : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? _kAccent : AppColors.textSecondary, letterSpacing: 0.5)),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Details Card ──────────────────────────────────────────────────────
        _SectionCard(title: 'Blast Details', icon: Icons.bolt_rounded, children: [
          _InfoRow(label: 'Blast Number', value: '#${blast['blast_number']}', icon: Icons.tag_rounded),
          _InfoRow(label: 'Blast Type', value: (blast['blast_type'] ?? '').toString().toUpperCase(), icon: Icons.category_rounded),
          _InfoRow(label: 'Blast Date', value: blastDt != null ? dateFormat.format(blastDt) : '—', icon: Icons.calendar_today_rounded),
          _InfoRow(label: 'Status', value: status.toUpperCase(), icon: Icons.info_outline_rounded, valueColor: isActive ? _kAccent : AppColors.textSecondary),
        ]),
        const SizedBox(height: 12),

        // ── Drilling Card ─────────────────────────────────────────────────────
        _SectionCard(title: 'Drilling Info', icon: Icons.construction_rounded, children: [
          _InfoRow(label: 'Feet Drilled', value: '${blast['feet']} ft', icon: Icons.straighten_rounded),
          _InfoRow(label: 'Rate per Feet', value: '₹${blast['rate']}', icon: Icons.price_change_rounded),
          _InfoRow(label: 'Drilling Cost', value: '₹${NumberFormat('#,##,###').format((double.tryParse(blast['feet']?.toString() ?? '0') ?? 0) * (double.tryParse(blast['rate']?.toString() ?? '0') ?? 0))}', icon: Icons.calculate_rounded, valueColor: _kAccent, bold: true),
        ]),
        const SizedBox(height: 12),

        // ── Notes ─────────────────────────────────────────────────────────────
        if (blast['notes'] != null && blast['notes'].toString().isNotEmpty)
          _SectionCard(title: 'Notes', icon: Icons.notes_rounded, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(blast['notes'].toString(), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
            ),
          ]),

        // ── Meta ──────────────────────────────────────────────────────────────
        if (createdDt != null) ...[
          const SizedBox(height: 12),
          _SectionCard(title: 'Record Info', icon: Icons.history_rounded, children: [
            _InfoRow(label: 'Created At', value: DateFormat('dd MMM yyyy, hh:mm a').format(createdDt), icon: Icons.access_time_rounded),
          ]),
        ],
      ]),
    );
  }
}

// ─── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kAccent, Color(0xFFD35400)]), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: Colors.white, size: 13)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.2)),
      ]),
      Divider(color: AppColors.border.withValues(alpha: 0.6), height: 18),
      ...children,
    ])),
  );
}

// ─── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool bold;
  const _InfoRow({required this.label, required this.value, required this.icon, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
    ]),
  );
}
