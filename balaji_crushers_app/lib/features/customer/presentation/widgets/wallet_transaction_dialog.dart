import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class WalletTransactionDialog extends StatefulWidget {
  final int customerId;
  final String customerName;
  final Function(Map<String, dynamic>) onSave;

  const WalletTransactionDialog({super.key, required this.customerId, required this.customerName, required this.onSave});

  static Future<void> show(BuildContext context, {required int customerId, required String customerName, required Function(Map<String, dynamic>) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletTransactionDialog(customerId: customerId, customerName: customerName, onSave: onSave),
    );
  }

  @override
  State<WalletTransactionDialog> createState() => _WalletTransactionDialogState();
}

class _WalletTransactionDialogState extends State<WalletTransactionDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'credit';
  String _mode = 'cash';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_amountController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSave({
        'customer_id': widget.customerId,
        'transaction_type': _type,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'payment_mode': _mode,
        'description': _descController.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = _type == 'credit';
    final btnColor = isCredit ? AppColors.success : AppColors.error;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Wallet Transaction', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(widget.customerName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: _TypeBtn(label: 'Customer Paid', icon: Icons.arrow_downward_rounded, selected: isCredit, color: AppColors.success, onTap: () => setState(() => _type = 'credit'))),
                  const SizedBox(width: 10),
                  Expanded(child: _TypeBtn(label: 'Loan Given', icon: Icons.arrow_upward_rounded, selected: !isCredit, color: AppColors.error, onTap: () => setState(() => _type = 'debit'))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: _dec('Amount *', Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: _dec('Mode', Icons.payment_rounded),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                      ],
                      onChanged: (v) => setState(() => _mode = v ?? 'cash'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(controller: _descController, style: const TextStyle(fontSize: 14), decoration: _dec('Reference / Notes', Icons.notes_rounded)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: !_isSubmitting ? _submit : null,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save Transaction', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.border),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: selected ? Colors.white : color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}