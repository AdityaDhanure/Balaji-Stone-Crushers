import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/expense/data/models/expense_models.dart';
import 'package:balaji_crushers_app/features/expense/data/repositories/expense_repository.dart';
import 'package:balaji_crushers_app/features/expense/utils/expense_utils.dart';

DateTime _todayIstDate() {
  final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(ist.year, ist.month, ist.day);
}

String _formatExpenseDate(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Bottom sheet form to edit an existing manual expense.
class EditExpenseDialog extends ConsumerStatefulWidget {
  final Expense expense;
  final List<ExpenseCategory> categories;
  final VoidCallback? onSuccess;

  const EditExpenseDialog({super.key, required this.expense, required this.categories, this.onSuccess});

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required List<ExpenseCategory> categories,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExpenseDialog(expense: expense, categories: categories, onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<EditExpenseDialog> {
  late ExpenseCategory? _selectedCategory;
  late DateTime _expenseDate;
  late final TextEditingController _amountController;
  late final TextEditingController _vendorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _referenceController;
  late String _paymentMode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.where((c) => c.id == widget.expense.categoryId).firstOrNull
        ?? widget.categories.firstOrNull;
    _expenseDate = widget.expense.expenseDate;
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(0));
    _vendorController = TextEditingController(text: widget.expense.vendorName ?? '');
    _descriptionController = TextEditingController(text: widget.expense.description ?? '');
    _referenceController = TextEditingController(text: widget.expense.referenceNumber ?? '');
    _paymentMode = widget.expense.paymentMode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  bool get _isValid => _selectedCategory != null && _amountController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting || widget.expense.id == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ExpenseRepository().updateExpense(widget.expense.id!, {
        'category_id': _selectedCategory!.id.toString(),
        'expense_date': _formatExpenseDate(_expenseDate),
        'amount': _amountController.text,
        'payment_mode': _paymentMode,
        'vendor_name': _vendorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'reference_number': _referenceController.text.trim(),
      });
      widget.onSuccess?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      if (widget.expense.expenseNumber != null)
                        Text(widget.expense.expenseNumber!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FormSection(
                    title: 'Expense Info',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.accent,
                    children: [
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: _selectedCategory,
                        decoration: _inputDecoration('Category *', Icons.category_outlined),
                        items: widget.categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(children: [
                            Icon(expenseIconData(c.icon), size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ]),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: _inputDecoration('Amount *', Icons.currency_rupee_rounded, prefix: '₹ '),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _expenseDate,
                                firstDate: DateTime(2020),
                                lastDate: _todayIstDate().add(const Duration(days: 30)),
                              );
                              if (d != null) setState(() => _expenseDate = d);
                            },
                            child: InputDecorator(
                              decoration: _inputDecoration('Date', Icons.calendar_today_rounded),
                              child: Text(DateFormat('dd MMM yyyy').format(_expenseDate), style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMode,
                        decoration: _inputDecoration('Payment Mode', Icons.payment_rounded),
                        items: ['cash', 'bank', 'cheque', 'upi']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setState(() => _paymentMode = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FormSection(
                    title: 'Additional Info',
                    icon: Icons.notes_rounded,
                    accentColor: AppColors.accent,
                    children: [
                      TextField(
                        controller: _vendorController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration('Vendor / Party Name', Icons.storefront_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration('Description', Icons.notes_rounded),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _referenceController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration('Reference Number', Icons.tag_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Update button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isValid && !_isSubmitting ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSubmitting ? 'Updating...' : 'Update Expense', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.textSecondary) : null,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ─── FormSection ──────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final List<Widget> children;

  const _FormSection({required this.title, required this.icon, required this.children, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }
}
