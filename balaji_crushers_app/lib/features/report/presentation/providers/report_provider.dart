import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/features/report/data/repositories/report_repository.dart';

final reportRepositoryProvider = Provider((_) => ReportRepository());

String _reportDateValue(dynamic item) {
  if (item is! Map) return '';
  for (final key in ['invoice_date', 'expense_date', 'date', 'created_at']) {
    final value = item[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
}

// ─── Shared param types ────────────────────────────────────────────────────────

typedef DateRangeParams = ({DateTime startDate, DateTime endDate});

// ─── Providers ────────────────────────────────────────────────────────────────

final overviewSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, DateRangeParams>((ref, p) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getOverviewSummary(
    startDate: p.startDate,
    endDate: p.endDate,
  );
});

final salesReportProvider =
    FutureProvider.family<List<dynamic>, DateRangeParams>((ref, p) async {
  final repo = ref.watch(reportRepositoryProvider);
  return (await repo.getSalesReport(
    startDate: p.startDate,
    endDate: p.endDate,
  ))
    ..sort((a, b) => _reportDateValue(b).compareTo(_reportDateValue(a)));
});

final expenseSummaryReportProvider =
    FutureProvider.family<Map<String, dynamic>, DateRangeParams>((ref, p) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getExpenseSummary(
    startDate: p.startDate,
    endDate: p.endDate,
  );
});

final profitLossProvider =
    FutureProvider.family<Map<String, dynamic>, DateRangeParams>((ref, p) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getProfitLoss(
    startDate: p.startDate,
    endDate: p.endDate,
  );
});

final yearlyTrendProvider =
    FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getYearlyTrend(year);
});
