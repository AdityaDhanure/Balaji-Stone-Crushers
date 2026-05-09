import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/report/presentation/providers/report_provider.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/common.dart';

class SalesTab extends ConsumerWidget {
  final ({DateTime startDate, DateTime endDate}) dateRange;

  const SalesTab({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(salesReportProvider(
        (startDate: dateRange.startDate, endDate: dateRange.endDate)));

    return async.when(
      loading: () => const LoadingState(message: 'Loading sales...'),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (rows) {
        if (rows.isEmpty) {
          return const EmptyState(
            message: 'No sales for this period',
            icon: Icons.receipt_long_outlined,
          );
        }

        double totalSales = 0, totalCollected = 0, totalBalance = 0;
        for (final r in rows) {
          totalSales += _n(r['total_amount']);
          totalCollected += _n(r['amount_paid']);
          totalBalance += _n(r['balance']);
        }

        return Column(
          children: [
            // ── Summary header ───────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Sales Summary'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Sales',
                          value: FormatUtils.formatCurrency(totalSales),
                          icon: Icons.bar_chart_rounded,
                          color: AppColors.success,
                          subtitle: '${rows.length} invoices',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Collected',
                          value: FormatUtils.formatCurrency(totalCollected),
                          icon: Icons.check_circle_rounded,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Pending',
                          value: FormatUtils.formatCurrency(totalBalance),
                          icon: Icons.pending_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ── Invoice list ─────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final r = rows[i] as Map<String, dynamic>;
                  final amount = _n(r['total_amount']);
                  final paid = _n(r['amount_paid']);
                  final balance = _n(r['balance']);
                  final status = r['status'] as String? ?? '';
                  final date = _reportDate(r['invoice_date']);

                  Color statusColor;
                  IconData statusIcon;
                  switch (status) {
                    case 'paid':
                      statusColor = AppColors.success;
                      statusIcon = Icons.check_circle_rounded;
                      break;
                    case 'partial':
                      statusColor = AppColors.warning;
                      statusIcon = Icons.timelapse_rounded;
                      break;
                    default:
                      statusColor = AppColors.error;
                      statusIcon = Icons.cancel_rounded;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Left accent bar
                          Container(
                            width: 3,
                            height: 48,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Customer info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['customer_name'] as String? ??
                                      'Customer',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      r['invoice_number'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const Text(
                                      ' · ',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Amount + status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FormatUtils.formatCurrency(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon,
                                        size: 11, color: statusColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (balance > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${FormatUtils.formatCurrency(balance)} due',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  double _n(dynamic v) {
    if (v == null) return 0;

    if (v is num) return v.toDouble();

    return double.tryParse(v.toString()) ?? 0;
  }

  DateTime _reportDate(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return _nowIst();

    final hasExplicitTimezone =
        RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
    if (raw.contains('T') && hasExplicitTimezone) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
        return DateTime(ist.year, ist.month, ist.day);
      }
    }

    final datePart = raw.split('T').first;
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return _nowIst();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime _nowIst() {
    final ist =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateTime(ist.year, ist.month, ist.day);
  }
}
