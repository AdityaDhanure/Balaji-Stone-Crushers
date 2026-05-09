import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

class ExpenseListItem extends StatelessWidget {
  final dynamic expense;
  final bool isSmallScreen;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.isSmallScreen,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: ListTile(
        leading: Container(
          width: isSmallScreen ? 40 : 45,
          height: isSmallScreen ? 40 : 45,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_rounded, color: AppColors.accent),
        ),
        title: Text(expense['expense_type']?.toString().toUpperCase() ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense['description'] != null && expense['description'].toString().isNotEmpty)
              Text(expense['description'], style: const TextStyle(fontSize: 12)),
            Text(dateFormat.format(appParseIstDate(expense['expense_date']) ?? appTodayIstDate()), style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '₹${NumberFormat('#,##,###').format(double.tryParse(expense['amount'].toString()) ?? 0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            if (value == 'edit') { onEdit(); }
            else if (value == 'delete') { onDelete(); }
          },
          itemBuilder: (popupContext) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red))])),
          ],
        ),
      ],
    );
  }
}

class DateGroupedExpenseItem extends StatelessWidget {
  final dynamic dateGroup;
  final bool isSmallScreen;
  final DateFormat dateFormat;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  const DateGroupedExpenseItem({
    super.key,
    required this.dateGroup,
    required this.isSmallScreen,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final expenseDateStr = dateGroup['expense_date']?.toString();
    final totalAmount = double.tryParse(dateGroup['total_amount'].toString()) ?? 0;
    final entriesCount = int.tryParse(dateGroup['entries_count'].toString()) ?? 0;
    final expenseDateTime = _parseDate(expenseDateStr);
    final formattedDate = expenseDateTime != null ? dateFormat.format(expenseDateTime) : 'Unknown';
    final expensesList = _parseExpensesList();

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: ExpansionTile(
        leading: _buildDateIcon(expenseDateTime),
        title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$entriesCount entries • ₹${NumberFormat.compact().format(totalAmount)}', style: const TextStyle(fontSize: 12)),
        children: expensesList.map<Widget>((expenseItem) => _buildExpenseTile(expenseItem)).toList(),
      ),
    );
  }

  DateTime? _parseDate(String? dateStr) {
    return appParseIstDate(dateStr);
  }

  Widget _buildDateIcon(DateTime? dateTime) {
    return Container(
      width: isSmallScreen ? 40 : 45,
      height: isSmallScreen ? 40 : 45,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (dateTime != null) ...[
            Text(DateFormat('dd').format(dateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent)),
            Text(DateFormat('MMM').format(dateTime), style: const TextStyle(fontSize: 10, color: AppColors.accent)),
          ] else ...[
            const Icon(Icons.calendar_today, size: 20, color: AppColors.accent),
          ],
        ],
      ),
    );
  }

  List<dynamic> _parseExpensesList() {
    final expensesRaw = dateGroup['expenses'];
    if (expensesRaw is List) return expensesRaw;
    return [];
  }

  Widget _buildExpenseTile(dynamic expenseItem) {
    final expenseId = int.tryParse(expenseItem['id'].toString());
    return ListTile(
      dense: true,
      leading: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.accent),
      title: Text(expenseItem['expense_type']?.toString().toUpperCase() ?? 'UNKNOWN', style: const TextStyle(fontSize: 13)),
      subtitle: expenseItem['description'] != null && expenseItem['description'].toString().isNotEmpty
          ? Text(expenseItem['description'].toString(), style: const TextStyle(fontSize: 11))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${NumberFormat('#,##,###').format(double.tryParse(expenseItem['amount'].toString()) ?? 0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (value) {
              if (value == 'edit') { onEdit(expenseItem); }
              else if (value == 'delete' && expenseId != null) { onDelete(expenseId); }
            },
            itemBuilder: (popupContext) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }
}

class ExpenseSummaryCard extends StatelessWidget {
  final double totalExpenses;

  const ExpenseSummaryCard({super.key, required this.totalExpenses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(
            '₹${NumberFormat('#,##,###').format(totalExpenses)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
