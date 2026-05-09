import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/core/utils/ist_date_utils.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';

class SalarySlipPaymentDialog extends ConsumerStatefulWidget {
  final SalarySlip slip;

  const SalarySlipPaymentDialog({super.key, required this.slip});

  @override
  ConsumerState<SalarySlipPaymentDialog> createState() => _SalarySlipPaymentDialogState();
}

class _SalarySlipPaymentDialogState extends ConsumerState<SalarySlipPaymentDialog> {
  DateTime _paymentDate = appTodayIstDate();
  String _paymentMode   = 'Bank Transfer';
  final _transactionController = TextEditingController();
  bool _isLoading = false;

  static const _paymentModes = [
    ('Bank Transfer', Icons.account_balance_outlined),
    ('Cash',          Icons.money_rounded),
    ('Cheque',        Icons.receipt_outlined),
    ('UPI',           Icons.phone_android_rounded),
  ];

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with net salary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, Color(0xFF1E8449)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payment_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Process Payment',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(widget.slip.employeeName,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('NET', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 0.8)),
                      Text(
                        '₹${widget.slip.netSalary.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment date picker
                  const Text('Payment Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMMM yyyy').format(_paymentDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment mode
                  const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.2,
                    children: _paymentModes.map((m) {
                      final isSelected = _paymentMode == m.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _paymentMode = m.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.success : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(m.$2, size: 20,
                                  color: isSelected ? AppColors.success : AppColors.textSecondary),
                              const SizedBox(height: 4),
                              Text(m.$1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Transaction ID
                  const Text('Transaction / Reference ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _transactionController,
                    decoration: InputDecoration(
                      hintText: 'Optional — UTR, cheque no., etc.',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),

                  // Bank details if available
                  if (widget.slip.bankAccount != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_outlined, size: 13, color: AppColors.info),
                              SizedBox(width: 6),
                              Text('Bank Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${widget.slip.bankName ?? ""} — ${widget.slip.bankAccount ?? ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          if (widget.slip.ifscCode != null)
                            Text('IFSC: ${widget.slip.ifscCode}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _processPayment,
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: appTodayIstDate(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(salaryNotifierProvider.notifier).processPayment(
        widget.slip.id!,
        paymentDate:   _paymentDate,
        paymentMode:   _paymentMode,
        transactionId: _transactionController.text.isNotEmpty ? _transactionController.text.trim() : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
