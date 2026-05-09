import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/report/presentation/providers/report_provider.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/common.dart';

class YearlyTrendTab extends ConsumerWidget {
  final int year;

  const YearlyTrendTab({super.key, required this.year});

  static const _months = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];
  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(yearlyTrendProvider(year));

    return async.when(
      loading: () =>
          const LoadingState(message: 'Loading yearly trend...'),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (rows) {
        final sales = List<double>.filled(12, 0);
        final expenses = List<double>.filled(12, 0);
        final netProfit = List<double>.filled(12, 0);
        double totalSales = 0, totalExpenses = 0;

        for (final r in rows) {
          final m = int.tryParse(r['month']?.toString() ?? '1') ?? 1;
          final monthIndex = m - 1;
          if (monthIndex < 0 || monthIndex > 11) continue;
          sales[monthIndex] = _n(r['total_sales']);
          expenses[monthIndex] = _n(r['total_expenses']);
          netProfit[monthIndex] = _n(r['net_profit']);
          totalSales += sales[monthIndex];
          totalExpenses += expenses[monthIndex];
        }

        final maxY = [...sales, ...expenses]
                .fold<double>(0, (m, v) => v > m ? v : m) *
            1.2;
        final isProfit = totalSales >= totalExpenses;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Year summary cards ───────────────────
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Year Revenue',
                      value: FormatUtils.formatCurrency(totalSales),
                      icon: Icons.trending_up_rounded,
                      color: AppColors.success,
                      subtitle: year.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Year Expenses',
                      value: FormatUtils.formatCurrency(totalExpenses),
                      icon: Icons.payments_rounded,
                      color: AppColors.error,
                      subtitle: year.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                title: isProfit ? 'Net Profit' : 'Net Loss',
                value: FormatUtils.formatCurrency(
                    (totalSales - totalExpenses).abs()),
                icon: isProfit
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isProfit ? AppColors.success : AppColors.error,
                subtitle: year.toString(),
                fullWidth: true,
              ),
              const SizedBox(height: 24),

              // ── Chart ────────────────────────────────
              const SectionTitle(title: 'Monthly Comparison'),
              const SizedBox(height: 8),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LegendDot(
                      color: AppColors.success, label: 'Revenue'),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: AppColors.error, label: 'Expenses'),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY > 0 ? maxY : 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem:
                              (group, groupIdx, rod, rodIdx) {
                            final name = rodIdx == 0
                                ? 'Revenue'
                                : 'Expenses';
                            final color = rodIdx == 0
                                ? AppColors.success
                                : AppColors.error;
                            return BarTooltipItem(
                              '$name\n${FormatUtils.formatCurrency(rod.toY)}',
                              TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _months[v.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            reservedSize: 24,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            interval: maxY > 0 ? maxY / 4 : 25,
                            getTitlesWidget: (v, _) => Text(
                              FormatUtils.formatNumber(v),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            maxY > 0 ? maxY / 4 : 25,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(12, (i) {
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 3,
                          barRods: [
                            BarChartRodData(
                              toY: sales[i],
                              color: AppColors.success,
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                            BarChartRodData(
                              toY: expenses[i],
                              color: AppColors.error,
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Monthly table ────────────────────────
              const SectionTitle(title: 'Monthly Breakdown'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Month',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Revenue',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Expenses',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'P / L',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rows
                    ...List.generate(12, (i) {
                      final pl = netProfit[i];
                      final plColor =
                          pl >= 0 ? AppColors.success : AppColors.error;
                      final isEven = i % 2 == 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: isEven
                            ? Colors.transparent
                            : AppColors.background.withOpacity(0.5),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _monthsFull[i],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                FormatUtils.formatCurrency(sales[i]),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                FormatUtils.formatCurrency(expenses[i]),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                FormatUtils.formatCurrency(pl.abs()),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: plColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Total row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(13)),
                        border: const Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              FormatUtils.formatCurrency(totalSales),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              FormatUtils.formatCurrency(totalExpenses),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              FormatUtils.formatCurrency(
                                  (totalSales - totalExpenses).abs()),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isProfit
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}
