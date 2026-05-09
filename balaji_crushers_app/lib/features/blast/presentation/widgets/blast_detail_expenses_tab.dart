import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

const _kAccent = Color(0xFFE67E22);

class ExpensesTab extends StatelessWidget {
  final List<dynamic> expenses;
  final double totalExpenses;
  final bool isSmallScreen;
  final bool groupByDate;
  final List<dynamic> dateGroupedExpenses;
  final List<dynamic> expenseDates;
  final bool loadingDateExpenses;
  final Function() onLoadDateGroupedExpenses;
  final Function(String) onToggleGroupBy;
  final Function(dynamic) onEditExpense;

  const ExpensesTab({
    super.key,
    required this.expenses,
    required this.totalExpenses,
    required this.isSmallScreen,
    required this.groupByDate,
    required this.dateGroupedExpenses,
    required this.expenseDates,
    required this.loadingDateExpenses,
    required this.onLoadDateGroupedExpenses,
    required this.onToggleGroupBy,
    required this.onEditExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty && !groupByDate) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.border),
        SizedBox(height: 14),
        Text('No expenses recorded', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('Add an expense using the + button', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]));
    }
    return Column(children: [
      _buildTotalCard(),
      _buildToggle(),
      Expanded(child: groupByDate ? _buildDateList() : _buildAllList()),
    ]);
  }

  Widget _buildTotalCard() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_kAccent.withValues(alpha: 0.12), _kAccent.withValues(alpha: 0.04)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: _kAccent, size: 18)),
        const SizedBox(width: 12),
        const Text('Total Expenses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('₹${NumberFormat('#,##,###').format(totalExpenses)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kAccent)),
      ]),
    ),
  );

  Widget _buildToggle() {
    final count = groupByDate ? expenseDates.length : expenses.length;
    final label = groupByDate ? 'dates' : 'entries';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(children: [
        _Chip(label: 'All', selected: !groupByDate, onTap: () => onToggleGroupBy('all')),
        const SizedBox(width: 8),
        _Chip(label: 'By Date', selected: groupByDate, onTap: () { if (!groupByDate) { onToggleGroupBy('date'); onLoadDateGroupedExpenses(); } }),
        const Spacer(),
        Text('$count $label', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildAllList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
    itemCount: expenses.length,
    itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _ExpenseCard(expense: expenses[i], onEdit: () => onEditExpense(expenses[i]))),
  );

  Widget _buildDateList() {
    if (loadingDateExpenses) return const Center(child: CircularProgressIndicator());
    if (dateGroupedExpenses.isEmpty) return const Center(child: Text('No date-wise expenses', style: TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      itemCount: dateGroupedExpenses.length,
      itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _DateExpenseCard(dateGroup: dateGroupedExpenses[i], onEdit: onEditExpense)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: selected ? _kAccent : AppColors.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

class _ExpenseCard extends StatelessWidget {
  final dynamic expense; final VoidCallback onEdit;
  const _ExpenseCard({required this.expense, required this.onEdit});

  Color _typeColor(String? type) {
    switch (type) { case 'drilling': return const Color(0xFFE67E22); case 'labour': return const Color(0xFF3498DB); case 'material': return const Color(0xFF2ECC71); case 'machinery': return const Color(0xFF9B59B6); case 'transport': return const Color(0xFF1ABC9C); default: return AppColors.textSecondary; }
  }

  @override
  Widget build(BuildContext context) {
    final type = expense['expense_type']?.toString() ?? 'other';
    final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0;
    String dateLabel = '';
    final parsedExpenseDate = appParseIstDate(expense['expense_date']);
    if (parsedExpenseDate != null) dateLabel = DateFormat('dd MMM yyyy').format(parsedExpenseDate);
    final description = expense['description']?.toString() ?? '';
    final color = _typeColor(type);

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 4, height: 68, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)))),
        const SizedBox(width: 12),
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(type[0].toUpperCase() + type.substring(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          if (description.isNotEmpty) ...[const SizedBox(height: 2), Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)],
          Text(dateLabel, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]))),
        Padding(padding: const EdgeInsets.only(right: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('₹${NumberFormat('#,##,###').format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Material(color: AppColors.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6),
              child: InkWell(onTap: onEdit, borderRadius: BorderRadius.circular(6),
                  child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.edit_rounded, size: 12, color: AppColors.textSecondary)))),
        ])),
      ]),
    );
  }
}

class _DateExpenseCard extends StatelessWidget {
  final dynamic dateGroup; final Function(dynamic) onEdit;
  const _DateExpenseCard({required this.dateGroup, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    dt = appParseIstDate(dateGroup['expense_date']);
    final dateLabel = dt != null ? DateFormat('dd MMM yyyy').format(dt) : 'Unknown';
    final totalAmount = double.tryParse(dateGroup['total_amount']?.toString() ?? '0') ?? 0;
    final entriesCount = dateGroup['entries_count']?.toString() ?? '0';
    final expensesList = _parseList(dateGroup['expenses']);

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading: dt != null ? _DateBadge(dt: dt) : const Icon(Icons.calendar_today_rounded, color: _kAccent),
          title: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text('$entriesCount entries · ₹${NumberFormat.compact().format(totalAmount)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          children: expensesList.map<Widget>((item) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: _kAccent),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((item['expense_type'] ?? 'other').toString()[0].toUpperCase() + (item['expense_type'] ?? 'other').toString().substring(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                if ((item['description']?.toString() ?? '').isNotEmpty) Text(item['description'].toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ])),
              Text('₹${NumberFormat('#,##,###').format(double.tryParse(item['amount']?.toString() ?? '0') ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Material(color: AppColors.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6),
                  child: InkWell(onTap: () => onEdit(item), borderRadius: BorderRadius.circular(6),
                      child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.edit_rounded, size: 12, color: AppColors.textSecondary)))),
            ]),
          )).toList(),
        )),
    );
  }

  List<dynamic> _parseList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime dt;
  const _DateBadge({required this.dt});
  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kAccent.withValues(alpha: 0.2))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(DateFormat('dd').format(dt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kAccent)),
      Text(DateFormat('MMM').format(dt), style: const TextStyle(fontSize: 9, color: _kAccent)),
    ]),
  );
}
