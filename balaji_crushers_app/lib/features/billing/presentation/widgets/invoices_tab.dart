import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';
import '../../utils/billing_date_utils.dart';
import 'invoice_card.dart';

class InvoicesTab extends ConsumerStatefulWidget {
  final String? status;
  final DateTimeRange? dateRange;
  final bool isSmallScreen;
  final Function(Invoice) onInvoiceTap;
  final Function(Invoice) onPay;

  const InvoicesTab({
    super.key,
    required this.status,
    required this.dateRange,
    required this.isSmallScreen,
    required this.onInvoiceTap,
    required this.onPay,
  });

  @override
  ConsumerState<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<InvoicesTab> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    var invoices = widget.status == null
        ? state.invoices
        : state.invoices.where((i) => i.status == widget.status).toList();

    // Date filter
    if (widget.dateRange != null) {
      invoices = invoices.where((i) {
        try {
          final date = billingParseDate(i.invoiceDate);
          final start = DateTime(
            widget.dateRange!.start.year,
            widget.dateRange!.start.month,
            widget.dateRange!.start.day,
          );
          final end = DateTime(
            widget.dateRange!.end.year,
            widget.dateRange!.end.month,
            widget.dateRange!.end.day,
          );
          return !date.isBefore(start) && !date.isAfter(end);
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      invoices = invoices.where((i) {
        return (i.invoiceNumber.toLowerCase().contains(q)) ||
            (i.billNo?.toLowerCase().contains(q) ?? false) ||
            (i.customerName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by Bill No., Invoice No. or Customer…',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        // Count row
        if (invoices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '${invoices.length} ${invoices.length == 1 ? 'invoice' : 'invoices'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    'for "$_searchQuery"',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        // List
        Expanded(
          child: invoices.isEmpty
              ? _EmptyState(
                  isSearching: _searchQuery.isNotEmpty,
                  status: widget.status,
                )
              : ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (_, i) {
                    final inv = invoices[i];
                    return InvoiceCard(
                      invoice: inv,
                      isSmallScreen: widget.isSmallScreen,
                      onTap: () => widget.onInvoiceTap(inv),
                      onPay: () => widget.onPay(inv),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final String? status;
  const _EmptyState({required this.isSearching, required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 44,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No matching invoices' : 'No invoices yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different bill no., invoice no. or name'
                : status != null
                    ? 'No ${status!} invoices found'
                    : 'Create your first invoice',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
