import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/core/providers/session_ui_state_provider.dart';
import 'package:balaji_crushers_app/core/utils/ist_date_utils.dart';
import 'package:balaji_crushers_app/features/report/presentation/providers/report_provider.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/report_period_selector.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/report_pdf_service.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/tabs/tabs.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key});

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ReportPeriod _period = ReportPeriod.monthly;
  DateTime _anchorDate = appTodayIstDate();
  bool _pdfLoading = false;

  static const _tabs = [
    (label: 'Overview', icon: Icons.dashboard_outlined),
    (label: 'Sales', icon: Icons.bar_chart_rounded),
    (label: 'Expenses', icon: Icons.payments_outlined),
    (label: 'Profit / Loss', icon: Icons.trending_up_rounded),
    (label: 'Yearly Trend', icon: Icons.show_chart_rounded),
  ];

  void _refreshCurrentTab() {
    final dr = _dateRange;
    final params = (startDate: dr.startDate, endDate: dr.endDate);

    switch (_tabController.index) {
      case 0:
        ref.invalidate(overviewSummaryProvider(params));
        break;
      case 1:
        ref.invalidate(salesReportProvider(params));
        break;
      case 2:
        ref.invalidate(expenseSummaryReportProvider(params));
        break;
      case 3:
        ref.invalidate(profitLossProvider(params));
        break;
      case 4:
        ref.invalidate(yearlyTrendProvider(_anchorDate.year));
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(sessionTabIndexProvider('reports')).clamp(0, _tabs.length - 1).toInt();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      ref.read(sessionTabIndexProvider('reports').notifier).state = _tabController.index;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ({DateTime startDate, DateTime endDate}) get _dateRange =>
      periodDateRange(_period, _anchorDate);

  Future<void> _downloadPdf() async {
    if (_pdfLoading) return;
    setState(() => _pdfLoading = true);
    try {
      final dr = _dateRange;
      final params = (startDate: dr.startDate, endDate: dr.endDate);

      switch (_tabController.index) {
        case 0:
          final data =
              await ref.read(overviewSummaryProvider(params).future);
          await ReportPdfService.printOverview(
              data, dr.startDate, dr.endDate);
          break;
        case 1:
          final data =
              await ref.read(salesReportProvider(params).future);
          await ReportPdfService.printSales(
              data, dr.startDate, dr.endDate);
          break;
        case 2:
          final data =
              await ref.read(expenseSummaryReportProvider(params).future);
          await ReportPdfService.printExpenses(
              data, dr.startDate, dr.endDate);
          break;
        case 3:
          final data =
              await ref.read(profitLossProvider(params).future);
          await ReportPdfService.printProfitLoss(
              data, dr.startDate, dr.endDate);
          break;
        case 4:
          final data =
              await ref.read(yearlyTrendProvider(_anchorDate.year).future);
          await ReportPdfService.printYearlyTrend(
              data, _anchorDate.year);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dr = _dateRange;
    final params = (startDate: dr.startDate, endDate: dr.endDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Period selector ──────────────────────────
          ReportPeriodSelector(
            period: _period,
            selectedDate: _anchorDate,
            onPeriodChanged: (p) {
              setState(() => _period = p);
              _refreshCurrentTab();
            },

            onDateChanged: (d) {
              setState(() => _anchorDate = d);
              _refreshCurrentTab();
            },
          ),

          // ── Tab bar ──────────────────────────────────
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(2),
                insets: const EdgeInsets.symmetric(horizontal: 8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.border,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _tabs
                  .map((t) => Tab(
                        height: 44,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 15),
                            const SizedBox(width: 5),
                            Text(t.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // ── Tab views ────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(dateRange: params),
                SalesTab(dateRange: params),
                ExpensesTab(dateRange: params),
                ProfitLossTab(dateRange: params),
                YearlyTrendTab(year: _anchorDate.year),
              ],
            ),
          ),
        ],
      ),

      // ── PDF FAB ─────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: _pdfLoading
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _pdfLoading ? Colors.grey.shade400 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pdfLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _pdfLoading ? null : _downloadPdf,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pdfLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                  const SizedBox(width: 8),
                  Text(
                    _pdfLoading ? 'Generating...' : 'Download PDF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
