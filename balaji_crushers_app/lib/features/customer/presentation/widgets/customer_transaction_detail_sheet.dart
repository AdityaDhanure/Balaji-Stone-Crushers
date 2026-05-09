import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/customer_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class CustomerTransactionDetailSheet extends ConsumerStatefulWidget {
  final Customer customer;
  final List<Invoice> pendingInvoices;

  const CustomerTransactionDetailSheet({super.key, required this.customer, required this.pendingInvoices});

  static void show(BuildContext context, {required Customer customer, required List<Invoice> pendingInvoices}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerTransactionDetailSheet(customer: customer, pendingInvoices: pendingInvoices),
    );
  }

  @override
  ConsumerState<CustomerTransactionDetailSheet> createState() => _CustomerTransactionDetailSheetState();
}

class _CustomerTransactionDetailSheetState extends ConsumerState<CustomerTransactionDetailSheet> {
  final _fmt = NumberFormat('#,##,###');

  @override
  Widget build(BuildContext context) {
    final totalBillingDue = widget.pendingInvoices.fold<double>(0, (s, inv) => s + inv.balanceDue);
    final walletBalance = widget.customer.currentBalance;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(widget.customer.name[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('${widget.customer.customerCode} • ${widget.customer.typeDisplay}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Billing dues section
                _SectionHeader(
                  title: 'Billing Dues',
                  badge: totalBillingDue > 0 ? '₹${_fmt.format(totalBillingDue)} pending' : 'All Clear',
                  badgeColor: totalBillingDue > 0 ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(height: 8),
                if (widget.pendingInvoices.isEmpty)
                  _ClearRow()
                else
                  ...widget.pendingInvoices.map((inv) => _InvoiceRow(invoice: inv, fmt: _fmt, onPay: () => _showPaymentDialog(inv))),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                // Wallet section
                _SectionHeader(
                  title: 'Wallet Balance',
                  badge: walletBalance == 0 ? 'Settled' : walletBalance > 0 ? '₹${_fmt.format(walletBalance.abs())} Advance' : '₹${_fmt.format(walletBalance.abs())} Pending',
                  badgeColor: walletBalance == 0 ? AppColors.textSecondary : walletBalance > 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(height: 12),
                // Add wallet transaction button
                GestureDetector(
                  onTap: _showAddWalletDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: AppColors.success),
                        SizedBox(width: 6),
                        Text('Add Wallet Transaction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Invoice invoice) {
    final amtCtrl = TextEditingController(text: invoice.balanceDue.toStringAsFixed(0));
    final refCtrl = TextEditingController();
    String mode = 'cash';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${_fmt.format(invoice.balanceDue)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                  ])),
              const SizedBox(height: 14),
              TextField(controller: amtCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ ', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                ],
                onChanged: (v) => setDS(() => mode = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference / Transaction ID', border: OutlineInputBorder(), hintText: 'Optional', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text) ?? 0;
                if (amount <= 0) return;
                final nav = Navigator.of(dialogCtx);
                final rootNav = Navigator.of(context);
                final success = await ref.read(billingProvider.notifier).recordPayment(invoice.id, amount, mode, reference: refCtrl.text.isEmpty ? null : refCtrl.text);
                if (success && mounted) {
                  nav.pop();
                  rootNav.pop();
                  ref.read(billingProvider.notifier).loadAllData();
                  ref.read(customerProvider.notifier).loadCustomers();
                }
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog() {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'credit';
    String mode = 'cash';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Wallet Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'credit', label: Text('Customer Paid'), icon: Icon(Icons.arrow_downward_rounded, size: 14)),
                  ButtonSegment(value: 'debit', label: Text('Loan Given'), icon: Icon(Icons.arrow_upward_rounded, size: 14)),
                ],
                selected: {type},
                onSelectionChanged: (s) => setDS(() => type = s.first),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ ', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: const InputDecoration(labelText: 'Mode', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  items: const [DropdownMenuItem(value: 'cash', child: Text('Cash')), DropdownMenuItem(value: 'bank', child: Text('Bank')), DropdownMenuItem(value: 'upi', child: Text('UPI')), DropdownMenuItem(value: 'cheque', child: Text('Cheque'))],
                  onChanged: (v) => setDS(() => mode = v ?? 'cash'),
                )),
              ]),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Reference / Notes', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                if (amtCtrl.text.isEmpty) return;
                final nav = Navigator.of(dialogCtx);
                final rootNav = Navigator.of(context);
                final success = await ref.read(customerProvider.notifier).addTransaction({
                  'customer_id': widget.customer.id,
                  'transaction_type': type,
                  'amount': double.tryParse(amtCtrl.text) ?? 0,
                  'payment_mode': mode,
                  'description': descCtrl.text,
                });
                if (success && mounted) {
                  nav.pop();
                  rootNav.pop();
                  ref.read(customerProvider.notifier).loadCustomers();
                }
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  const _SectionHeader({required this.title, required this.badge, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeColor.withValues(alpha: 0.3))),
          child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
        ),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat fmt;
  final VoidCallback onPay;
  const _InvoiceRow({required this.invoice, required this.fmt, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM').format(appParseIstDate(invoice.invoiceDate) ?? appTodayIstDate());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$date • ${invoice.items.length} item${invoice.items.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${fmt.format(invoice.balanceDue)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13)),
            const Text('due', style: TextStyle(fontSize: 9, color: AppColors.warning)),
          ]),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), elevation: 0),
            child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ClearRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Text('No pending invoices', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
