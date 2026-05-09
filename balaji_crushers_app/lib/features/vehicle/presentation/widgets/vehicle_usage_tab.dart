import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

class VehicleUsageTab extends StatefulWidget {
  final List<dynamic> usage;
  final bool groupUsageByDate;
  final List<dynamic> dateGroupedUsage;
  final List<dynamic> usageDates;
  final bool loadingDateUsage;
  final VoidCallback onLoadDateGroupedUsage;
  final Function(bool) onToggleGroupBy;
  final Function(dynamic) onEditUsage;

  const VehicleUsageTab({
    super.key,
    required this.usage,
    required this.groupUsageByDate,
    required this.dateGroupedUsage,
    required this.usageDates,
    required this.loadingDateUsage,
    required this.onLoadDateGroupedUsage,
    required this.onToggleGroupBy,
    required this.onEditUsage,
  });

  @override
  State<VehicleUsageTab> createState() => _VehicleUsageTabState();
}

class _VehicleUsageTabState extends State<VehicleUsageTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.usage.isEmpty && !widget.groupUsageByDate) {
      return const _EmptyUsage();
    }

    return Column(children: [
      _ViewToggle(groupByDate: widget.groupUsageByDate, onChanged: (v) {
        widget.onToggleGroupBy(v);
        if (v) widget.onLoadDateGroupedUsage();
      }),
      Expanded(
        child: widget.groupUsageByDate ? _buildGroupedView() : _buildFlatView(),
      ),
    ]);
  }

  Widget _buildFlatView() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.usage.length,
      itemBuilder: (_, i) => _UsageCard(usage: widget.usage[i], onEdit: () => widget.onEditUsage(widget.usage[i])),
    );
  }

  Widget _buildGroupedView() {
    if (widget.loadingDateUsage) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (widget.dateGroupedUsage.isEmpty) return const _EmptyUsage();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.dateGroupedUsage.length,
      itemBuilder: (_, i) {
        final g = widget.dateGroupedUsage[i];
        final dateStr = g['usage_date']?.toString();
        final count = int.tryParse(g['entries_count']?.toString() ?? '0') ?? 0;
        DateTime? dt = appParseIstDate(dateStr);

        List<dynamic> entries = [];
        final raw = g['usage_records'];
        if (raw is List) { entries = raw; }
        else if (raw is String && raw.isNotEmpty) { try { final d = jsonDecode(raw); if (d is List) entries = d; } catch (_) {} }

        return _DateGroupCard(
          dateTime: dt,
          formattedDate: dt != null ? DateFormat('dd MMM yyyy').format(dt) : 'Unknown',
          subtitle: '$count usage records',
          accentColor: AppColors.primary,
          children: entries.map<Widget>((e) => _UsageRow(entry: e, onEdit: () => widget.onEditUsage(e))).toList(),
        );
      },
    );
  }
}

// ─── Usage Card (flat) ─────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final dynamic usage;
  final VoidCallback onEdit;
  const _UsageCard({required this.usage, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    DateTime? dt = appParseIstDate(usage['usage_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 3, height: 50, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Container(
            width: isSmall ? 40 : 44, height: isSmall ? 40 : 44,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.06)]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(usage['purpose']?.toString() ?? 'General', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            if (usage['location'] != null && usage['location'].toString().isNotEmpty)
              Text(usage['location'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(dt != null ? DateFormat('dd MMM yyyy').format(dt) : '', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) { if (v == 'edit') onEdit(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 15, color: AppColors.primary), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─── Usage Row (inside grouped card) ──────────────────────────────────────────

class _UsageRow extends StatelessWidget {
  final dynamic entry;
  final VoidCallback onEdit;
  const _UsageRow({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final location = entry['location']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(children: [
        const Icon(Icons.route_rounded, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry['purpose']?.toString() ?? 'General', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (location != null && location.isNotEmpty)
            Text(location, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 15, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (v) { if (v == 'edit') onEdit(); },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 15, color: AppColors.primary), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
          ],
        ),
      ]),
    );
  }
}

// ─── Shared Components ─────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final bool groupByDate;
  final Function(bool) onChanged;
  const _ViewToggle({required this.groupByDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Text('View by:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(width: 10),
        _Pill(label: 'All Entries', selected: !groupByDate, onTap: () => onChanged(false)),
        const SizedBox(width: 8),
        _Pill(label: 'By Date', selected: groupByDate, onTap: () => onChanged(true)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _DateGroupCard extends StatelessWidget {
  final DateTime? dateTime;
  final String formattedDate;
  final String subtitle;
  final List<Widget> children;
  final Color accentColor;
  const _DateGroupCard({required this.dateTime, required this.formattedDate, required this.subtitle, required this.children, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: dateTime != null
              ? Container(width: 44, height: 44, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('dd').format(dateTime!), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
                    Text(DateFormat('MMM').format(dateTime!), style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.w600)),
                  ]))
              : Icon(Icons.calendar_today_rounded, color: accentColor),
          title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          children: children,
        ),
      ),
    );
  }
}

class _EmptyUsage extends StatelessWidget {
  const _EmptyUsage();

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.route_outlined, size: 44, color: AppColors.primary.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      const Text('No usage records', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      const Text('Add a usage record using the button below', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]));
  }
}
