import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';
import '../../utils/billing_date_utils.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Invoice invoice;
  final Function(double, String, String?, DateTime) onPay;
  const RecordPaymentDialog({super.key, required this.invoice, required this.onPay});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  late TextEditingController _amountController;
  final _referenceController = TextEditingController();
  String _paymentMode = 'cash';
  DateTime _paymentDate = billingTodayIstDate();
  bool _isPaying = false;

  static const _modes = [
    ('cash', 'Cash', Icons.money_rounded),
    ('bank_transfer', 'Bank Transfer', Icons.account_balance_rounded),
    ('cheque', 'Cheque', Icons.receipt_rounded),
    ('rtgs', 'RTGS / NEFT', Icons.flash_on_rounded),
    ('upi', 'UPI', Icons.smartphone_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.invoice.balanceDue.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final balance = widget.invoice.balanceDue;
    final inv = widget.invoice;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payment_rounded,
                      color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Record Payment',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(inv.customerName ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Invoice info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryLight.withValues(alpha: 0.04),
                ]),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  _infoRow('Invoice', inv.invoiceNumber),
                  if (inv.billNo != null && inv.billNo!.isNotEmpty)
                    _infoRow('Bill No.', inv.billNo!),
                  _infoRow('Total', '₹${fmt.format(inv.totalAmount)}'),
                  _infoRow('Paid', '₹${fmt.format(inv.amountPaid)}',
                      valueColor: AppColors.success),
                  const Divider(height: 14, color: AppColors.border),
                  _infoRow('Balance Due', '₹${fmt.format(balance)}',
                      isHighlight: true,
                      valueColor: AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quick amount chips
            const Text('Quick Amount',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _quickChip(balance, 'Full', fmt),
                if (balance > 0) _quickChip(balance / 2, 'Half', fmt),
                if (balance > 0) _quickChip(balance / 4, 'Quarter', fmt),
              ],
            ),
            const SizedBox(height: 14),
            _label('Amount *'),
            const SizedBox(height: 8),
            _field(
              controller: _amountController,
              hint: '0',
              icon: Icons.currency_rupee_rounded,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _label('Payment Mode'),
            const SizedBox(height: 8),
            // Mode selector chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((m) {
                final selected = _paymentMode == m.$1;
                return GestureDetector(
                  onTap: () => setState(() => _paymentMode = m.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.$3,
                            size: 14,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(m.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _label('Reference / Transaction ID'),
            const SizedBox(height: 8),
            _field(
              controller: _referenceController,
              hint: 'Optional — cheque no., UPI ref…',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 14),
            _label('Payment Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy').format(_paymentDate),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.success.withValues(alpha: 0.4),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isPaying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('CONFIRM PAYMENT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid amount'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    setState(() => _isPaying = true);
    Navigator.pop(context);
    widget.onPay(
      amount,
      _paymentMode,
      _referenceController.text.isEmpty ? null : _referenceController.text,
      _paymentDate,
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: billingTodayIstDate(),
    );
    if (d != null) setState(() => _paymentDate = d);
  }

  Widget _quickChip(double amount, String label, NumberFormat fmt) =>
      GestureDetector(
        onTap: () =>
            setState(() => _amountController.text = amount.toStringAsFixed(0)),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            '$label  ₹${fmt.format(amount)}',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
          ),
        ),
      );

  Widget _infoRow(String label, String value,
          {Color? valueColor, bool isHighlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: isHighlight ? 15 : 12,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary)),
          ],
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
            prefixIcon:
                Icon(icon, size: 16, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}
