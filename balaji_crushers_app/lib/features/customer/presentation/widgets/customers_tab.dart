import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/customer_provider.dart';
import 'customer_card.dart';
import 'customer_filter_bar.dart';

class CustomersTab extends ConsumerStatefulWidget {
  final bool showActiveOnly;
  final ValueChanged<bool> onToggle;
  final Function(Customer) onCustomerTap;

  const CustomersTab({
    super.key,
    required this.showActiveOnly,
    required this.onToggle,
    required this.onCustomerTap,
  });

  @override
  ConsumerState<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<CustomersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);

    if (state.isLoading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    // Filter: active/all
    var displayed = widget.showActiveOnly
        ? state.customers.where((c) => c.isActive).toList()
        : state.customers;

    // Filter: search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayed = displayed.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.customerCode.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false) ||
          (c.city?.toLowerCase().contains(q) ?? false)).toList();
    }

    return Column(
      children: [
        CustomerFilterBar(
          showActiveOnly: widget.showActiveOnly,
          totalCount: state.customers.length,
          activeCount: state.customers.where((c) => c.isActive).length,
          onToggle: widget.onToggle,
          searchController: _searchController,
          onSearchChanged: (q) => setState(() => _searchQuery = q),
        ),
        Expanded(
          child: displayed.isEmpty
              ? _EmptyState(
                  isFiltered: _searchQuery.isNotEmpty,
                  showActiveOnly: widget.showActiveOnly,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 100),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) => CustomerCard(
                    customer: displayed[index],
                    onTap: () => widget.onCustomerTap(displayed[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final bool showActiveOnly;
  const _EmptyState({required this.isFiltered, required this.showActiveOnly});

  @override
  Widget build(BuildContext context) {
    final icon = isFiltered ? Icons.search_off_rounded : Icons.people_outline_rounded;
    final title = isFiltered
        ? 'No results found'
        : showActiveOnly
            ? 'No active customers'
            : 'No customers yet';
    final subtitle = isFiltered
        ? 'Try a different name, phone or code'
        : 'Add your first customer using the button below';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}