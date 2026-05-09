import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/report/presentation/providers/report_provider.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/common.dart';

class ExpensesTab extends ConsumerWidget {
  final ({DateTime startDate, DateTime endDate}) dateRange;

  const ExpensesTab({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseSummaryReportProvider(
        (startDate: dateRange.startDate, endDate: dateRange.endDate)));

    return async.when(
      loading: () => const LoadingState(message: 'Loading expenses...'),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (d) {
        final total = _n(d['total']);
        final manual = _n(d['manual']);
        final dieselPaid = _n(d['diesel_paid']);
        final dieselPending = _n(d['diesel_pending']);
        final blast = _n(d['blast']);
        final royalty = _n(d['royalty']);
        final maintenance = _n(d['maintenance']);
        final salariesPaid = _n(d['salaries_paid']);
        final salariesPending = _n(d['salaries_pending']);
        final advances = _n(d['advances']);
        final production = _n(d['production_cost']);

        final sources = [
          _ExpItem('Manual Expenses', manual, Icons.receipt_long_rounded,
              const Color(0xFF2196F3)),
          _ExpItem('Diesel (Paid)', dieselPaid,
              Icons.local_gas_station_rounded, const Color(0xFF4CAF50)),
          if (dieselPending > 0)
            _ExpItem('Diesel (Pending)', dieselPending,
                Icons.local_gas_station_rounded, AppColors.warning,
                isPending: true),
          _ExpItem('Blast / Drilling', blast, Icons.flash_on_rounded,
              const Color(0xFFF44336)),
          _ExpItem('Royalty', royalty, Icons.account_balance_rounded,
              const Color(0xFF9C27B0)),
          _ExpItem('Maintenance', maintenance, Icons.build_rounded,
              const Color(0xFFFF9800)),
          _ExpItem('Salaries (Paid)', salariesPaid, Icons.people_rounded,
              const Color(0xFF3F51B5)),
          if (salariesPending > 0)
            _ExpItem('Salaries (Pending)', salariesPending,
                Icons.people_rounded, AppColors.warning,
                isPending: true),
          _ExpItem('Salary Advances', advances,
              Icons.account_balance_wallet_rounded, const Color(0xFF009688)),
          _ExpItem('Production Cost', production, Icons.factory_rounded,
              const Color(0xFF607D8B)),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Total hero ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade800,
                      Colors.red.shade500,
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
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          FormatUtils.formatCurrency(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Breakdown ────────────────────────────
              const SectionTitle(title: 'Breakdown by Source'),
              const SizedBox(height: 12),

              ...sources.map((s) => _buildExpenseRow(s, total, context)),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseRow(
      _ExpItem s, double total, BuildContext context) {
    final pct = total > 0 ? (s.amount / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: s.color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: s.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(s.icon, color: s.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (s.isPending)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                FormatUtils.formatCurrency(s.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: s.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: s.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(s.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _n(dynamic v) {
    if (v == null) return 0;

    if (v is num) return v.toDouble();

    return double.tryParse(v.toString()) ?? 0;
  }
}

class _ExpItem {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isPending;

  const _ExpItem(
    this.label,
    this.amount,
    this.icon,
    this.color, {
    this.isPending = false,
  });
}
