import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/diesel_provider.dart';
import '../../utils/diesel_date_utils.dart';

class DieselConsumptionTab extends StatefulWidget {
  final List<DieselConsumption> consumption;
  final bool groupConsumptionByDate;
  final List<dynamic> dateGroupedConsumption;
  final bool loadingDateConsumption;
  final VoidCallback onLoadDateGroupedConsumption;
  final Function(bool) onToggleGroupBy;
  final Function(DieselConsumption) onEdit;

  const DieselConsumptionTab({
    super.key,
    required this.consumption,
    required this.groupConsumptionByDate,
    required this.dateGroupedConsumption,
    required this.loadingDateConsumption,
    required this.onLoadDateGroupedConsumption,
    required this.onToggleGroupBy,
    required this.onEdit,
  });

  @override
  State<DieselConsumptionTab> createState() => _DieselConsumptionTabState();
}

class _DieselConsumptionTabState extends State<DieselConsumptionTab> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _DieselViewToggle(
        groupByDate: widget.groupConsumptionByDate,
        onChanged: (grouped) {
          widget.onToggleGroupBy(grouped);
          if (grouped) widget.onLoadDateGroupedConsumption();
        },
      ),
      Expanded(
        child: widget.groupConsumptionByDate
            ? _buildGroupedView()
            : _buildFlatView(),
      ),
    ]);
  }

  Widget _buildFlatView() {
    if (widget.consumption.isEmpty) {
      return const _DieselEmptyState(icon: Icons.speed_outlined, message: 'No consumption recorded', sub: 'Add a consumption entry using the button below');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.consumption.length,
      itemBuilder: (_, i) => _ConsumptionCard(item: widget.consumption[i], onEdit: () => widget.onEdit(widget.consumption[i])),
    );
  }

  Widget _buildGroupedView() {
    if (widget.loadingDateConsumption) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (widget.dateGroupedConsumption.isEmpty) {
      return const _DieselEmptyState(icon: Icons.speed_outlined, message: 'No consumption recorded', sub: 'Add a consumption entry using the button below');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.dateGroupedConsumption.length,
      itemBuilder: (_, i) {
        final g = widget.dateGroupedConsumption[i];
        final dateStr = g['consumption_date']?.toString() ?? '';
        final totalQty = double.tryParse(g['total_quantity']?.toString() ?? '0') ?? 0;
        final count = int.tryParse(g['entries_count']?.toString() ?? '0') ?? 0;
        final dt = dieselParseDate(dateStr);

        List<dynamic> entries = [];
        final raw = g['entries'];
        if (raw is List) { entries = raw; }
        else if (raw is String && raw.isNotEmpty) { try { final d = jsonDecode(raw); if (d is List) entries = d; } catch (_) {} }

        return _DieselDateGroupCard(
          dateTime: dt,
          formattedDate: DateFormat('dd MMM yyyy').format(dt),
          subtitle: '$count entries · ${totalQty.toStringAsFixed(1)} L',
          accentColor: AppColors.info,
          children: entries.map<Widget>((e) {
            final entryId = int.tryParse(e['id']?.toString() ?? '');
            final qty = double.tryParse(e['quantity']?.toString() ?? '0') ?? 0;
            return _ConsumptionRow(
              entry: e,
              qty: qty,
              onEdit: entryId != null ? () {
                widget.onEdit(DieselConsumption(
                  id: entryId,
                  vehicleId: int.tryParse(e['vehicle_id']?.toString() ?? '0') ?? 0,
                  vehicleNumber: e['vehicle_number']?.toString() ?? '',
                  vehicleType: e['vehicle_type']?.toString() ?? '',
                  quantity: qty,
                  consumptionDate: dateStr,
                  purpose: e['purpose']?.toString(),
                ));
              } : null,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ConsumptionCard extends StatelessWidget {
  final DieselConsumption item;
  final VoidCallback onEdit;
  const _ConsumptionCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
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
          Container(width: 3, height: 50, decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.info.withValues(alpha: 0.15), AppColors.info.withValues(alpha: 0.07)]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_shipping_rounded, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(item.purpose ?? 'General Use', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(DateFormat('dd MMM yyyy').format(dieselParseDate(item.consumptionDate)), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ])),
          Text('${item.quantity.toStringAsFixed(1)} L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.info)),
          const SizedBox(width: 4),
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

class _ConsumptionRow extends StatelessWidget {
  final dynamic entry;
  final double qty;
  final VoidCallback? onEdit;
  const _ConsumptionRow({required this.entry, required this.qty, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final purpose = entry['purpose']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(children: [
        const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.info),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry['vehicle_number']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (purpose != null && purpose.isNotEmpty)
            Text(purpose, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        Text('${qty.toStringAsFixed(1)} L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.info)),
        if (onEdit != null) ...[
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) { if (v == 'edit') onEdit!(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 15, color: AppColors.primary), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
            ],
          ),
        ],
      ]),
    );
  }
}

// ─── Inline Shared Widgets ────────────────────────────────────────────────────

class _DieselViewToggle extends StatelessWidget {
  final bool groupByDate;
  final Function(bool) onChanged;
  const _DieselViewToggle({required this.groupByDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Text('View by:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(width: 10),
        _DieselPill(label: 'All Entries', selected: !groupByDate, onTap: () => onChanged(false)),
        const SizedBox(width: 8),
        _DieselPill(label: 'By Date', selected: groupByDate, onTap: () => onChanged(true)),
      ]),
    );
  }
}

class _DieselPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DieselPill({required this.label, required this.selected, required this.onTap});

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

class _DieselDateGroupCard extends StatelessWidget {
  final DateTime? dateTime;
  final String formattedDate;
  final String subtitle;
  final List<Widget> children;
  final Color accentColor;
  const _DieselDateGroupCard({required this.dateTime, required this.formattedDate, required this.subtitle, required this.children, required this.accentColor});

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
              ? Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('dd').format(dateTime!), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
                    Text(DateFormat('MMM').format(dateTime!), style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.w600)),
                  ]),
                )
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

class _DieselEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _DieselEmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(icon, size: 44, color: AppColors.primary.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]));
  }
}
