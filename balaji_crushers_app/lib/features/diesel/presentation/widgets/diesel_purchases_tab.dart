import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/diesel_provider.dart';
import '../../utils/diesel_date_utils.dart';

class DieselPurchasesTab extends StatefulWidget {
  final List<DieselPurchase> purchases;
  final bool isLoading;
  final bool groupPurchasesByDate;
  final Function(bool) onToggleGroupBy;
  final Function(int) onMarkPaid;

  const DieselPurchasesTab({
    super.key,
    required this.purchases,
    required this.isLoading,
    required this.groupPurchasesByDate,
    required this.onToggleGroupBy,
    required this.onMarkPaid,
  });

  @override
  State<DieselPurchasesTab> createState() => _DieselPurchasesTabState();
}

class _DieselPurchasesTabState extends State<DieselPurchasesTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.purchases.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Column(children: [
      _ViewToggle(groupByDate: widget.groupPurchasesByDate, onChanged: widget.onToggleGroupBy),
      Expanded(
        child: widget.purchases.isEmpty
            ? const _EmptyState(icon: Icons.local_gas_station_outlined, message: 'No purchases recorded', sub: 'Add a diesel purchase using the button below')
            : widget.groupPurchasesByDate
                ? _buildDateGrouped()
                : _buildFlat(),
      ),
    ]);
  }

  Widget _buildFlat() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: widget.purchases.length,
      itemBuilder: (_, i) => _PurchaseCard(purchase: widget.purchases[i], onMarkPaid: () => widget.onMarkPaid(widget.purchases[i].id)),
    );
  }

  Widget _buildDateGrouped() {
    final Map<String, List<DieselPurchase>> grouped = {};
    for (final p in widget.purchases) {
      grouped.putIfAbsent(dieselDateString(p.purchaseDate), () => []).add(p);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: dates.length,
      itemBuilder: (_, i) {
        final dateKey = dates[i];
        final items = grouped[dateKey]!;
        final dt = dieselParseDate(dateKey);
        final totalQty = items.fold<double>(0, (s, p) => s + p.quantity);
        final pendingAmt = items.where((p) => !p.isPaid).fold<double>(0, (s, p) => s + p.totalAmount);

        return _DateGroupCard(
          dateTime: dt,
          formattedDate: DateFormat('dd MMM yyyy').format(dt),
          subtitle: '${items.length} purchases · ${totalQty.toStringAsFixed(1)} L${pendingAmt > 0 ? ' · Pending ₹${NumberFormat('#,##,###').format(pendingAmt)}' : ''}',
          accentColor: AppColors.primary,
          children: items.map((p) => _PurchaseRow(purchase: p, onMarkPaid: () => widget.onMarkPaid(p.id))).toList(),
        );
      },
    );
  }
}

// ─── Purchase Card ────────────────────────────────────────────────────────────

class _PurchaseCard extends StatelessWidget {
  final DieselPurchase purchase;
  final VoidCallback onMarkPaid;
  const _PurchaseCard({required this.purchase, required this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
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
          Container(width: 3, height: 50, decoration: BoxDecoration(color: purchase.isPaid ? AppColors.success : AppColors.warning, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.07)]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(purchase.pumpName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text('${purchase.quantity.toStringAsFixed(1)} L @ ₹${purchase.ratePerLiter.toStringAsFixed(2)}/L', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(DateFormat('dd MMM yyyy').format(dieselParseDate(purchase.purchaseDate)), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text('₹${fmt.format(purchase.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            _PaymentBadge(isPaid: purchase.isPaid),
          ]),
          const SizedBox(width: 4),
          if (!purchase.isPaid)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (v) { if (v == 'mark_paid') onMarkPaid(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'mark_paid', child: Row(children: [Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success), SizedBox(width: 8), Text('Mark Paid', style: TextStyle(fontSize: 13))])),
              ],
            ),
        ]),
      ),
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  final DieselPurchase purchase;
  final VoidCallback onMarkPaid;
  const _PurchaseRow({required this.purchase, required this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(children: [
        const Icon(Icons.local_gas_station_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(purchase.pumpName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('${purchase.quantity.toStringAsFixed(1)} L @ ₹${purchase.ratePerLiter.toStringAsFixed(2)}/L', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        Text('₹${fmt.format(purchase.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        _PaymentBadge(isPaid: purchase.isPaid),
        if (!purchase.isPaid) ...[
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) { if (v == 'mark_paid') onMarkPaid(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'mark_paid', child: Row(children: [Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success), SizedBox(width: 8), Text('Mark Paid', style: TextStyle(fontSize: 13))])),
            ],
          ),
        ],
      ]),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final bool isPaid;
  const _PaymentBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: isPaid ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Text(isPaid ? 'PAID' : 'PENDING',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: isPaid ? AppColors.success : AppColors.warning, letterSpacing: 0.5)),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

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
