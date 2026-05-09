import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';
import '../../utils/billing_date_utils.dart';
import 'status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final bool isSmallScreen;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.isSmallScreen,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final isOverdue = _isOverdue;
    final accentColor = _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOverdue
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Invoice icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt_long_rounded,
                                color: accentColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Invoice number + Bill No
                                Row(
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (invoice.billNo != null &&
                                        invoice.billNo!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Bill# ${invoice.billNo}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  invoice.customerName ?? 'Unknown Customer',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${fmt.format(invoice.totalAmount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              BillingStatusBadge(status: invoice.status),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Date and items row
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(invoice.invoiceDate),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('OVERDUE',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error)),
                            ),
                          ],
                          const Spacer(),
                          if (invoice.status != 'paid' &&
                              invoice.status != 'cancelled')
                            GestureDetector(
                              onTap: onPay,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.success
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.payment_rounded,
                                        size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text('Pay',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Progress bar for partial/pending
                      if (invoice.status == 'partial' ||
                          invoice.status == 'pending') ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: invoice.totalAmount > 0
                                ? (invoice.amountPaid / invoice.totalAmount)
                                    .clamp(0.0, 1.0)
                                : 0,
                            backgroundColor:
                                AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.info),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${fmt.format(invoice.amountPaid)} paid  ·  Balance ₹${fmt.format(invoice.balanceDue)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isOverdue {
    if (invoice.status == 'paid' || invoice.status == 'cancelled') return false;
    if (invoice.dueDate == null) return false;
    try {
      return billingParseDate(invoice.dueDate).isBefore(billingTodayIstDate());
    } catch (_) {
      return false;
    }
  }

  Color get _accentColor {
    switch (invoice.status) {
      case 'paid':
        return AppColors.success;
      case 'partial':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return _isOverdue ? AppColors.error : AppColors.primary;
    }
  }

  String _formatDate(String raw) {
    try {
      final d = billingParseDate(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }
}
