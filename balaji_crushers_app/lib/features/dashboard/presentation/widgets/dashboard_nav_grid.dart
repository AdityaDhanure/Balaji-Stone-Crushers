import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _NavItem({required this.label, required this.icon, required this.color, required this.route});
}

const _allNavItems = [
  _NavItem(label: 'Blast', icon: Icons.bolt_rounded, color: Color(0xFFE67E22), route: '/blast'),
  _NavItem(label: 'Vehicles', icon: Icons.local_shipping_rounded, color: Color(0xFF3498DB), route: '/vehicles'),
  _NavItem(label: 'Diesel', icon: Icons.local_gas_station_rounded, color: Color(0xFFE74C3C), route: '/diesel'),
  _NavItem(label: 'Crusher', icon: Icons.factory_rounded, color: Color(0xFF8E44AD), route: '/crusher'),
  _NavItem(label: 'Customers', icon: Icons.people_rounded, color: Color(0xFF27AE60), route: '/customers'),
  _NavItem(label: 'Billing', icon: Icons.receipt_long_rounded, color: Color(0xFF16A085), route: '/billing'),
  _NavItem(label: 'Maintenance', icon: Icons.build_rounded, color: Color(0xFFF39C12), route: '/maintenance'),
  _NavItem(label: 'Employees', icon: Icons.badge_rounded, color: Color(0xFF2980B9), route: '/employees'),
  _NavItem(label: 'Attendance', icon: Icons.checklist_rounded, color: Color(0xFF1ABC9C), route: '/attendance'),
  _NavItem(label: 'Salary', icon: Icons.payments_rounded, color: Color(0xFF27AE60), route: '/salary'),
  _NavItem(label: 'Expenses', icon: Icons.account_balance_wallet_rounded, color: Color(0xFFE74C3C), route: '/expenses'),
  _NavItem(label: 'Reports', icon: Icons.bar_chart_rounded, color: Color(0xFF2C3E50), route: '/reports'),
];

// ─── Full Modules Grid ──────────────────────────────────────────────────────────
class DashboardModulesGrid extends StatelessWidget {
  final bool isSmallScreen;
  const DashboardModulesGrid({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final cols = isSmallScreen ? 3 : 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _allNavItems.length,
      itemBuilder: (_, i) => _ModuleCard(item: _allNavItems[i]),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _NavItem item;
  const _ModuleCard({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [item.color.withValues(alpha: 0.12), item.color.withValues(alpha: 0.04)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(item.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

// ─── Quick Action Buttons Row ──────────────────────────────────────────────────
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  static const _actions = [
    _NavItem(label: 'New Blast', icon: Icons.bolt_rounded, color: Color(0xFFE67E22), route: '/blast/new'),
    _NavItem(label: 'New Bill', icon: Icons.receipt_long_rounded, color: Color(0xFF16A085), route: '/billing'),
    _NavItem(label: 'Add Expense', icon: Icons.add_card_rounded, color: Color(0xFFE74C3C), route: '/expenses'),
    _NavItem(label: 'Reports', icon: Icons.bar_chart_rounded, color: Color(0xFF2C3E50), route: '/reports'),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: _actions.map((a) => Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _QuickBtn(item: a),
    ))).toList(),
  );
}

class _QuickBtn extends StatelessWidget {
  final _NavItem item;
  const _QuickBtn({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [item.color, Color.lerp(item.color, Colors.black, 0.2)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
