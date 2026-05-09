import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/customer_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class TransactionsTab extends ConsumerWidget {
  final Function(Customer, List<Invoice>) onCustomerTap;

  const TransactionsTab({super.key, required this.onCustomerTap});

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'company':    return Icons.business_rounded;
      case 'government': return Icons.account_balance_rounded;
      default:           return Icons.person_rounded;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'company':    return AppColors.primary;
      case 'government': return AppColors.accent;
      default:           return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerState = ref.watch(customerProvider);
    final billingState = ref.watch(billingProvider);
    final fmt = NumberFormat('#,##,###');

    if (customerState.isLoading && customerState.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    // Build invoice map for pending/partial only
    final Map<int, List<Invoice>> invoicesByCustomer = {};
    for (final inv in billingState.invoices) {
      if (inv.customerId != null && (inv.status == 'pending' || inv.status == 'partial')) {
        invoicesByCustomer.putIfAbsent(inv.customerId!, () => []).add(inv);
      }
    }

    // Build entries list
    final entries = <Map<String, dynamic>>[];
    for (final customer in customerState.customers) {
      final pendingInvoices = invoicesByCustomer[customer.id] ?? [];
      final billingBalance = pendingInvoices.fold<double>(0, (s, inv) => s + inv.balanceDue);
      final walletBalance = customer.currentBalance;
      if (billingBalance > 0 || walletBalance != 0) {
        entries.add({
          'customer': customer,
          'billing_balance': billingBalance,
          'wallet_balance': walletBalance,
          'pending_invoices': pendingInvoices,
        });
      }
    }

    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    entries.sort((a, b) {
      final diff = (b['billing_balance'] as double).compareTo(a['billing_balance'] as double);
      if (diff != 0) return diff;
      return (b['wallet_balance'] as double).abs().compareTo((a['wallet_balance'] as double).abs());
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final customer = entry['customer'] as Customer;
        final billingBalance = entry['billing_balance'] as double;
        final walletBalance = entry['wallet_balance'] as double;
        final pendingInvoices = entry['pending_invoices'] as List<Invoice>;
        final color = _typeColor(customer.customerType);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onCustomerTap(customer, pendingInvoices),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer identity row
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: customer.customerType == 'individual'
                                ? Text(customer.name[0].toUpperCase(), style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))
                                : Icon(_typeIcon(customer.customerType), color: color, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                              Text(customer.customerCode, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Balance chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (billingBalance > 0)
                          _BalanceChip(
                            icon: Icons.receipt_long_rounded,
                            label: '₹${fmt.format(billingBalance)}',
                            sublabel: '${pendingInvoices.length} bill${pendingInvoices.length > 1 ? 's' : ''} pending',
                            color: AppColors.warning,
                          ),
                        if (walletBalance != 0)
                          _BalanceChip(
                            icon: Icons.account_balance_wallet_rounded,
                            label: '₹${fmt.format(walletBalance.abs())}',
                            sublabel: walletBalance > 0 ? 'Advance Paid' : 'Loan Pending',
                            color: walletBalance > 0 ? AppColors.success : AppColors.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded, size: 44, color: AppColors.success.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          const Text('All Clear!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('No pending transactions or dues', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _BalanceChip({required this.icon, required this.label, required this.sublabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              Text(sublabel, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}