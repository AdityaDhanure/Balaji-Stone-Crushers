import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/product_provider.dart';

class ProductionTab extends StatefulWidget {
  final List<ProductionEntry> production;
  final bool isLoading;
  final bool groupProductionByDate;
  final List<Map<String, dynamic>> dateGroupedProduction;
  final bool loadingDateGroupedProduction;
  final VoidCallback onLoadDateGroupedProduction;
  final Function(bool) onToggleGroupBy;
  final Function(ProductionEntry) onEdit;

  const ProductionTab({
    super.key,
    required this.production,
    required this.isLoading,
    required this.groupProductionByDate,
    required this.dateGroupedProduction,
    required this.loadingDateGroupedProduction,
    required this.onLoadDateGroupedProduction,
    required this.onToggleGroupBy,
    required this.onEdit,
  });

  @override
  State<ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<ProductionTab> {
  final _fmt = NumberFormat('#,##,###');
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ViewToggle(
          groupByDate: widget.groupProductionByDate,
          onChanged: (grouped) {
            widget.onToggleGroupBy(grouped);
            if (grouped) widget.onLoadDateGroupedProduction();
          },
        ),
        Expanded(
          child: widget.groupProductionByDate
              ? _buildGroupedView()
              : _buildFlatView(),
        ),
      ],
    );
  }

  Widget _buildFlatView() {
    if (widget.isLoading && widget.production.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (widget.production.isEmpty) {
      return const _EmptyState(icon: Icons.analytics_outlined, message: 'No production recorded', sub: 'Add a production entry using the button below');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.production.length,
      itemBuilder: (_, i) {
        final e = widget.production[i];
        return _ProductionCard(entry: e, fmt: _fmt, onEdit: () => widget.onEdit(e));
      },
    );
  }

  Widget _buildGroupedView() {
    if (widget.loadingDateGroupedProduction) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (widget.dateGroupedProduction.isEmpty) {
      return const _EmptyState(icon: Icons.analytics_outlined, message: 'No production recorded', sub: 'Add a production entry using the button below');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.dateGroupedProduction.length,
      itemBuilder: (_, i) => _DateGroupCard(
        group: widget.dateGroupedProduction[i],
        fmt: _fmt,
        dateFmt: _dateFmt,
        onEdit: widget.onEdit,
      ),
    );
  }
}

// ─── View Toggle ─────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final bool groupByDate;
  final Function(bool) onChanged;
  const _ViewToggle({required this.groupByDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text('View by:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          _Pill(label: 'All Entries', selected: !groupByDate, onTap: () => onChanged(false)),
          const SizedBox(width: 8),
          _Pill(label: 'By Date', selected: groupByDate, onTap: () => onChanged(true)),
        ],
      ),
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
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

// ─── Production Entry Card ────────────────────────────────────────────────────

class _ProductionCard extends StatelessWidget {
  final ProductionEntry entry;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  const _ProductionCard({required this.entry, required this.fmt, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dateStr = entry.productionDate.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(appParseIstDate(entry.productionDate)!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.info.withValues(alpha: 0.2), AppColors.info.withValues(alpha: 0.08)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      if (entry.sizeMm != null)
                        Text('${entry.sizeMm}mm', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${fmt.format(entry.totalValue)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
                    Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                  onSelected: (v) { if (v == 'edit') onEdit(); },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 15, color: AppColors.primary), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(child: _Detail(label: 'Quantity', value: '${entry.quantityTons.toStringAsFixed(1)} brass', icon: Icons.straighten_rounded)),
                  Expanded(child: _Detail(label: 'Rate/brass', value: '₹${entry.productionRatePerBrass.toStringAsFixed(0)}', icon: Icons.currency_rupee_rounded)),
                  Expanded(child: _Detail(label: 'Royalty', value: '₹${fmt.format(entry.royaltyAmount)}', icon: Icons.account_balance_rounded)),
                  Expanded(child: _Detail(label: 'Transport', value: '₹${fmt.format(entry.transportationCost)}', icon: Icons.local_shipping_rounded)),
                ],
              ),
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.notes_rounded, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Expanded(child: Text(entry.notes!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Detail({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Date Grouped Card ────────────────────────────────────────────────────────

class _DateGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final Function(ProductionEntry) onEdit;
  const _DateGroupCard({required this.group, required this.fmt, required this.dateFmt, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dateStr = group['production_date']?.toString() ?? '';
    final entryCount = group['entry_count'] ?? 0;
    final totalQty = (group['total_quantity'] ?? 0).toDouble();
    final totalVal = (group['total_value'] ?? 0).toDouble();

    DateTime? dt;
    dt = appParseIstDate(dateStr);
    final formattedDate = dt != null ? dateFmt.format(dt) : 'Unknown Date';

    List<dynamic> entries = [];
    final raw = group['entries'];
    if (raw is List) {
      entries = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try { final d = jsonDecode(raw); if (d is List) entries = d; } catch (_) {}
    }
    entries.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: dt != null
              ? Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('dd').format(dt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    Text(DateFormat('MMM').format(dt), style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                )
              : const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
          title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            '$entryCount entries · ${totalQty.toStringAsFixed(1)} brass · ₹${fmt.format(totalVal)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          children: entries.map<Widget>((e) {
            final id = int.tryParse(e['id'].toString());
            final name = e['product_name']?.toString() ?? 'Unknown';
            final sizeMm = e['size_mm'];
            final qty = double.tryParse(e['quantity_tons']?.toString() ?? '0') ?? 0;
            final rate = double.tryParse(e['rate_per_brass']?.toString() ?? '0') ?? 0;
            final val = double.tryParse(e['total_value']?.toString() ?? '0') ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sizeMm != null ? '$name ($sizeMm mm)' : name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${qty.toStringAsFixed(1)} brass @ ₹${rate.toStringAsFixed(0)}/brass',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text('₹${fmt.format(val)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                  if (id != null) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textSecondary),
                      onSelected: (v) {
                        if (v == 'edit') {
                          final prodId = int.tryParse(e['product_id']?.toString() ?? '0') ?? 0;
                          onEdit(ProductionEntry(
                            id: id,
                            productionDate: dateStr,
                            productId: prodId,
                            productName: name,
                            productCode: e['product_code']?.toString() ?? '',
                            sizeMm: sizeMm?.toInt(),
                            quantityTons: qty,
                            royaltyAmount: double.tryParse(e['royalty_amount']?.toString() ?? '0') ?? 0,
                            transportationCost: double.tryParse(e['transportation_cost']?.toString() ?? '0') ?? 0,
                            productionRatePerBrass: rate,
                            totalValue: val,
                            notes: e['notes']?.toString(),
                          ));
                        }
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 15, color: AppColors.primary), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
