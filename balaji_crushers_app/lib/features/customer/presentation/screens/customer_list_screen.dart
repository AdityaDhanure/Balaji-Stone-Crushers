import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/session_ui_state_provider.dart';
import '../providers/customer_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../billing/presentation/widgets/create_invoice_sheet.dart';
import '../widgets/customer_stats_card.dart';
import '../widgets/customers_tab.dart';
import '../widgets/transactions_tab.dart';
import '../widgets/customer_detail_sheet.dart';
import '../widgets/wallet_transaction_dialog.dart';
import '../widgets/customer_transaction_detail_sheet.dart';
import '../widgets/add_customer_sheet.dart';
import '../widgets/edit_customer_sheet.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(sessionTabIndexProvider('customers')).clamp(0, 1).toInt();
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      ref.read(sessionTabIndexProvider('customers').notifier).state = _tabController.index;
    });
    Future.microtask(() {
      ref.read(customerProvider.notifier).loadAllData();
      ref.read(billingProvider.notifier).loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats card (same padding as billing) ──
          Padding(
            padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, isSmall ? 12 : 20, isSmall ? 12 : 20, 0),
            child: CustomerStatsCard(customers: state.customers),
          ),
          const SizedBox(height: 12),
          // ── Tab bar (same style as billing section) ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
            child: Container(
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(
                    height: 44,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.people_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Customers'),
                    ]),
                  ),
                  Tab(
                    height: 44,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_long_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Transactions'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Tab content (expanded to fill remaining space) ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
              child: TabBarView(
                controller: _tabController,
                children: [
                  CustomersTab(
                    showActiveOnly: _showActiveOnly,
                    onToggle: (v) => setState(() => _showActiveOnly = v),
                    onCustomerTap: _showCustomerDetail,
                  ),
                  TransactionsTab(
                    onCustomerTap: _showCustomerTransactionDetail,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AddCustomerFAB(onPressed: _showAdd),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  void _showAdd() {
    AddCustomerSheet.show(context, onSave: (data) async {
      final nav = Navigator.of(context);
      final success = await ref.read(customerProvider.notifier).createCustomer(data);
      if (!mounted) return;
      if (success) {
        nav.pop();
        _showSnackbar('Customer added successfully', AppColors.success);
      }
    });
  }

  void _showCustomerDetail(Customer customer) {
    CustomerDetailSheet.show(
      context,
      customer,
      onEdit: () => _showEdit(customer),
      onCreateBill: () => _showCreateBill(customer),
      onAddWalletTransaction: () => _showWallet(customer),
    );
  }

  void _showEdit(Customer customer) {
    EditCustomerSheet.show(context, customer: customer, onSave: (data) async {
      final nav = Navigator.of(context);
      final success = await ref.read(customerProvider.notifier).updateCustomer(customer.id, data);
      if (!mounted) return;
      if (success) {
        nav.pop();
        _showSnackbar('Customer updated', AppColors.success);
      }
    });
  }

  void _showWallet(Customer customer) {
    WalletTransactionDialog.show(
      context,
      customerId: customer.id,
      customerName: customer.name,
      onSave: (data) async {
        final success = await ref.read(customerProvider.notifier).addTransaction(data);
        if (!mounted) return;
        if (success) {
          final nav = Navigator.of(context);
          await ref.read(customerProvider.notifier).loadAllData();
          nav.pop();
        }
      },
    );
  }

  void _showCreateBill(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateInvoiceSheet(
        preselectedCustomerId: customer.id,
        preselectedCustomerName: customer.name,
        onSave: (data) async {
          final nav = Navigator.of(ctx);
          final success = await ref.read(billingProvider.notifier).createInvoice(data);
          if (!mounted) return;
          if (success) {
            nav.pop();
            await ref.read(customerProvider.notifier).loadAllData();
            _showSnackbar('Invoice created successfully', AppColors.success);
          }
        },
      ),
    );
  }

  void _showCustomerTransactionDetail(Customer customer, List<Invoice> pendingInvoices) {
    CustomerTransactionDetailSheet.show(context, customer: customer, pendingInvoices: pendingInvoices);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _AddCustomerFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddCustomerFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }
}
