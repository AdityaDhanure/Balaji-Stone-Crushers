import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/report/presentation/providers/report_provider.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/common.dart';

class ProfitLossTab extends ConsumerWidget {
  final ({DateTime startDate, DateTime endDate}) dateRange;

  const ProfitLossTab({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profitLossProvider(
        (startDate: dateRange.startDate, endDate: dateRange.endDate)));

    return async.when(
      loading: () => const LoadingState(message: 'Loading P&L...'),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (d) {
        final totalSales = _n(d['totalSales']);
        final collected = _n(d['collected']);
        final pendingRevenue = _n(d['pendingRevenue']);
        final totalExpenses = _n(d['totalExpenses']);
        final netProfit = _n(d['netProfit']);
        final profitMargin = _n(d['profitMargin']);
        final costItems = (d['costBreakdown'] as List<dynamic>?) ?? [];
        final isProfit = netProfit >= 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Net P&L Hero ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isProfit
                        ? [
                            const Color(0xFF065F46),
                            const Color(0xFF059669),
                          ]
                        : [
                            const Color(0xFF7F1D1D),
                            const Color(0xFFDC2626),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isProfit
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isProfit ? 'Net Profit' : 'Net Loss',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                FormatUtils.formatCurrency(
                                    netProfit.abs()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${profitMargin.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Margin',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (totalSales > 0 || totalExpenses > 0) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 12),
                      _RevenueExpenseBar(
                          sales: totalSales, expenses: totalExpenses),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Revenue Section ──────────────────────
              const SectionTitle(title: 'Revenue'),
              const SizedBox(height: 10),
              PLCard(
                label: 'Total Sales',
                amount: totalSales,
                icon: Icons.bar_chart_rounded,
                color: AppColors.success,
              ),
              PLCard(
                label: 'Collected',
                amount: collected,
                icon: Icons.check_circle_rounded,
                color: AppColors.info,
              ),
              if (pendingRevenue > 0)
                PLCard(
                  label: 'Pending Revenue',
                  amount: pendingRevenue,
                  icon: Icons.pending_rounded,
                  color: AppColors.warning,
                  subtitle: 'Awaiting collection',
                ),
              const SizedBox(height: 20),

              // ── Cost Breakdown ───────────────────────
              const SectionTitle(title: 'Cost Breakdown'),
              const SizedBox(height: 10),
              ...costItems.map((item) {
                final m = item as Map<String, dynamic>;
                return PLCard(
                  label: m['label'] as String? ?? '',
                  amount: _n(m['amount']),
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.error,
                  isExpense: true,
                );
              }),
              const SizedBox(height: 8),

              // ── Total Expenses Footer ────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Total Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      FormatUtils.formatCurrency(totalExpenses),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  double _n(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _RevenueExpenseBar extends StatelessWidget {
  final double sales, expenses;

  const _RevenueExpenseBar(
      {required this.sales, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final max = sales > expenses ? sales : expenses;
    return Column(
      children: [
        _Bar(
          label: 'Revenue',
          value: max > 0 ? (sales / max) : 0,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        _Bar(
          label: 'Expenses',
          value: max > 0 ? (expenses / max) : 0,
          color: Colors.redAccent.shade100,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Bar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
