import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/report/presentation/providers/report_provider.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/common.dart';

class OverviewTab extends ConsumerWidget {
  final ({DateTime startDate, DateTime endDate}) dateRange;

  const OverviewTab({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(overviewSummaryProvider(
        (startDate: dateRange.startDate, endDate: dateRange.endDate)));

    return async.when(
      loading: () => const LoadingState(message: 'Loading overview...'),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (d) {
        final totalSales = _n(d['totalSales']);
        final totalExpenses = _n(d['totalExpenses']);
        final netProfit = _n(d['netProfit']);
        final pending = _n(d['pendingPayments']);
        final invoiceCount = (d['invoiceCount'] as num?)?.toInt() ?? 0;
        final res = d['resources'] as Map<String, dynamic>? ?? {};
        final isProfit = netProfit >= 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Net Profit Hero Banner ───────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isProfit
                        ? [
                            const Color(0xFF1E3A5F),
                            const Color(0xFF2E5D9F),
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
                child: Row(
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
                            FormatUtils.formatCurrency(netProfit.abs()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$invoiceCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Invoices',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Financial KPIs ───────────────────────
              const SectionTitle(title: 'Financial Overview'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Revenue',
                      value: FormatUtils.formatCurrency(totalSales),
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.success,
                      subtitle: '$invoiceCount invoices',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Expenses',
                      value: FormatUtils.formatCurrency(totalExpenses),
                      icon: Icons.payments_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                title: 'Pending Payments',
                value: FormatUtils.formatCurrency(pending),
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
                subtitle: 'From sales — awaiting collection',
                fullWidth: true,
              ),
              const SizedBox(height: 24),

              // ── Resource Status ──────────────────────
              const SectionTitle(title: 'Resource Status'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ResourceTile(
                      label: 'Active Vehicles',
                      value: '${res['activeVehicles'] ?? 0}',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResourceTile(
                      label: 'Active Employees',
                      value: '${res['activeEmployees'] ?? 0}',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF009688),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ResourceTile(
                      label: 'Diesel Stock',
                      value:
                          '${FormatUtils.formatNumber(_n(res['dieselStockLitres']))} L',
                      icon: Icons.local_gas_station_rounded,
                      color: const Color(0xFF795548),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResourceTile(
                      label: 'In Maintenance',
                      value: '${res['equipmentMaintenance'] ?? 0}',
                      icon: Icons.build_rounded,
                      color: const Color(0xFF673AB7),
                      subtitle: 'Equipment items',
                    ),
                  ),
                ],
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

class _ResourceTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _ResourceTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
