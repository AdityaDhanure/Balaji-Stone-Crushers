import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/customer_provider.dart';

class CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onCreateBill;
  final VoidCallback onAddWalletTransaction;

  const CustomerDetailSheet({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.onCreateBill,
    required this.onAddWalletTransaction,
  });

  static void show(
    BuildContext context,
    Customer customer, {
    required VoidCallback onEdit,
    required VoidCallback onCreateBill,
    required VoidCallback onAddWalletTransaction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerDetailSheet(
        customer: customer,
        onEdit: onEdit,
        onCreateBill: onCreateBill,
        onAddWalletTransaction: onAddWalletTransaction,
      ),
    );
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'company':    return AppColors.primary;
      case 'government': return AppColors.accent;
      default:           return AppColors.info;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'company':    return Icons.business_rounded;
      case 'government': return Icons.account_balance_rounded;
      default:           return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(customer.customerType);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            // Header card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: customer.customerType == 'individual'
                            ? Text(customer.name[0].toUpperCase(),
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color))
                            : Icon(_typeIcon(customer.customerType), color: color, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _InfoTag(label: customer.customerCode, color: color),
                              const SizedBox(width: 6),
                              _InfoTag(label: customer.typeDisplay, color: AppColors.textSecondary),
                              if (!customer.isActive) ...[
                                const SizedBox(width: 6),
                                _InfoTag(label: 'Inactive', color: AppColors.error),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Scrollable body
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Contact info
                  _InfoCard(
                    title: 'Contact Info',
                    icon: Icons.contact_phone_rounded,
                    rows: [
                      if (customer.phone != null) _InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: customer.phone!),
                      if (customer.email != null) _InfoRow(icon: Icons.email_rounded, label: 'Email', value: customer.email!),
                      if (customer.gstNumber != null) _InfoRow(icon: Icons.receipt_rounded, label: 'GST', value: customer.gstNumber!),
                    ],
                  ),
                  if (customer.fullAddress.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoCard(
                      title: 'Address',
                      icon: Icons.location_on_rounded,
                      rows: [
                        if (customer.billingAddress != null) _InfoRow(icon: Icons.home_rounded, label: 'Billing', value: customer.billingAddress!),
                        if (customer.city != null) _InfoRow(icon: Icons.location_city_rounded, label: 'City', value: '${customer.city}${customer.state != null ? ', ${customer.state}' : ''}'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          filled: false,
                          onTap: () {
                            Navigator.pop(context);
                            Future.microtask(onEdit);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Create Bill',
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.primary,
                          filled: true,
                          onTap: () {
                            Navigator.pop(context);
                            Future.microtask(onCreateBill);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ActionBtn(
                    label: 'Add Wallet Transaction',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.accent,
                    filled: false,
                    onTap: () {
                      Navigator.pop(context);
                      Future.microtask(onAddWalletTransaction);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoTag extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 13, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: filled ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}