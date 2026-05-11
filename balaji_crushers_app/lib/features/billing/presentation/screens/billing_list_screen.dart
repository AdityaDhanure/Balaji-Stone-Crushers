import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/session_ui_state_provider.dart';
import '../providers/billing_provider.dart';
import '../widgets/billing_stats_card.dart';
import '../widgets/invoices_tab.dart';
import '../widgets/create_invoice_sheet.dart';
import '../widgets/invoice_detail_sheet.dart';
import '../widgets/record_payment_dialog.dart';
import '../../utils/billing_date_utils.dart';

class BillingListScreen extends ConsumerStatefulWidget {
  const BillingListScreen({super.key});

  @override
  ConsumerState<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends ConsumerState<BillingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(sessionTabIndexProvider('billing')).clamp(0, 3).toInt();
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      ref.read(sessionTabIndexProvider('billing').notifier).state = _tabController.index;
    });
    Future.microtask(() => ref.read(billingProvider.notifier).loadAllData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(billingProvider.notifier).loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmall ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.error != null && state.error!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                  ]),
                ),
              BillingStatsCard(
                    stats: state.stats,
                    isSmallScreen: isSmall,
                  ),
              const SizedBox(height: 16),
              _buildDateFilter(),
              const SizedBox(height: 16),
              _buildTabs(state, isSmall),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _showCreateDialog,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('New Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _dateRange != null
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _dateRange != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded, size: 14,
                  color: _dateRange != null ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _dateRange == null
                    ? 'All Dates'
                    : '${DateFormat('dd/MM').format(_dateRange!.start)} – ${DateFormat('dd/MM').format(_dateRange!.end)}',
                style: TextStyle(
                    fontSize: 12,
                    color: _dateRange != null ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: _dateRange != null ? FontWeight.w600 : FontWeight.normal),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _dateRange = null),
                  child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BillingState state, bool isSmall) {
    final counts = {
      'all': state.invoices.length,
      'pending': state.invoices.where((i) => i.status == 'pending').length,
      'partial': state.invoices.where((i) => i.status == 'partial').length,
      'paid': state.invoices.where((i) => i.status == 'paid').length,
    };

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            padding: const EdgeInsets.all(4),
            tabs: [
              _tab('All', counts['all']!, Icons.receipt_long_rounded),
              _tab('Pending', counts['pending']!, Icons.schedule_rounded),
              _tab('Partial', counts['partial']!, Icons.pie_chart_rounded),
              _tab('Paid', counts['paid']!, Icons.check_circle_rounded),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 560,
          child: TabBarView(
            controller: _tabController,
            children: [
              InvoicesTab(status: null, dateRange: _dateRange, isSmallScreen: isSmall, onInvoiceTap: _showDetail, onPay: _showPayDialog),
              InvoicesTab(status: 'pending', dateRange: _dateRange, isSmallScreen: isSmall, onInvoiceTap: _showDetail, onPay: _showPayDialog),
              InvoicesTab(status: 'partial', dateRange: _dateRange, isSmallScreen: isSmall, onInvoiceTap: _showDetail, onPay: _showPayDialog),
              InvoicesTab(status: 'paid', dateRange: _dateRange, isSmallScreen: isSmall, onInvoiceTap: _showDetail, onPay: _showPayDialog),
            ],
          ),
        ),
      ],
    );
  }

  Tab _tab(String label, int count, IconData icon) => Tab(
        height: 44,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ]),
      );

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
        context: context, firstDate: DateTime(2020),
        lastDate: billingTodayIstDate().add(const Duration(days: 365)),
        initialDateRange: _dateRange);
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => CreateInvoiceSheet(
        onSave: (data) async {
          final nav = Navigator.of(context);
          final ok = await ref.read(billingProvider.notifier).createInvoice(data);
          if (!mounted) return;
          if (ok) { nav.pop(); _snack('Invoice created', AppColors.success); }
        },
      ),
    );
  }

  void _showDetail(Invoice invoice) {
    final notifier = ref.read(billingProvider.notifier);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => InvoiceDetailSheet(
        invoice: invoice,
        onRecordPayment: (amount, mode, txnRef, paymentDate) async {
          final ok = await notifier.recordPayment(
            invoice.id,
            amount,
            mode,
            reference: txnRef,
            paymentDate: paymentDate,
          );
          if (ok && mounted) {
            // ignore: use_build_context_synchronously
            Navigator.pop(ctx);
            notifier.loadAllData();
          }
        },
        onStatusChange: (status) async {
          await notifier.updateInvoiceStatus(invoice.id, status);
          notifier.loadAllData();
        },
        onEdit: () => _showEditDialog(invoice),
      ),
    );
  }

  void _showEditDialog(Invoice invoice) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => CreateInvoiceSheet(
        existingInvoice: invoice,
        onSave: (data) async {
          final nav = Navigator.of(context);
          final payload = {...data, 'status': invoice.status};
          final ok = await ref.read(billingProvider.notifier).updateInvoice(invoice.id, payload);
          if (!mounted) return;
          if (ok) { nav.pop(); _snack('Invoice updated', AppColors.success); }
        },
      ),
    );
  }

  void _showPayDialog(Invoice invoice) {
    final notifier = ref.read(billingProvider.notifier);
    showDialog(
      context: context,
      builder: (_) => RecordPaymentDialog(
        invoice: invoice,
        onPay: (amount, mode, txnRef, paymentDate) async {
          final ok = await notifier.recordPayment(
            invoice.id,
            amount,
            mode,
            reference: txnRef,
            paymentDate: paymentDate,
          );
          if (ok && mounted) {
            notifier.loadAllData();
            _snack('Payment recorded', AppColors.success);
          }
        },
      ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
