import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';
import '../../utils/billing_date_utils.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';

class CreateInvoiceSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final int? preselectedCustomerId;
  final String? preselectedCustomerName;
  final Invoice? existingInvoice;

  const CreateInvoiceSheet({
    super.key,
    required this.onSave,
    this.preselectedCustomerId,
    this.preselectedCustomerName,
    this.existingInvoice,
  });

  @override
  ConsumerState<CreateInvoiceSheet> createState() => _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends ConsumerState<CreateInvoiceSheet> {
  final _numberController = TextEditingController();
  final _billNoController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController();
  int? _selectedCustomerId;
  String _selectedCustomerName = '';
  final List<Map<String, dynamic>> _items = [];
  double _taxPercent = 0;
  DateTime _invoiceDate = billingTodayIstDate();
  DateTime? _dueDate;
  bool _isSubmitting = false;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingInvoice;
    if (existing != null) {
      // Edit mode — pre-populate all fields including items
      _selectedCustomerId = existing.customerId;
      _selectedCustomerName = existing.customerName ?? '';
      _billNoController.text = existing.billNo ?? '';
      _notesController.text = existing.notes ?? '';
      _taxPercent = existing.totalAmount > 0 && existing.taxAmount > 0
          ? (existing.taxAmount / (existing.totalAmount - existing.taxAmount)) *
                100
          : 0;
      if (_taxPercent > 0) _taxController.text = _taxPercent.toStringAsFixed(1);
      _invoiceDate = billingParseDate(existing.invoiceDate);
      if (existing.dueDate != null) {
        _dueDate = billingParseDate(existing.dueDate);
      }
      // Show any items already available immediately, then refresh from API.
      _items.addAll(existing.items.map(_editableItemFromInvoiceItem));
      Future.microtask(() async {
        ref.read(customerProvider.notifier).loadCustomers();
        ref.read(productProvider.notifier).loadProducts();
        _numberController.text = existing.invoiceNumber;
        if (mounted) setState(() => _loadingItems = true);
        try {
          final repo = ref.read(billingRepositoryProvider);
          final apiItems = await repo.getItemsByInvoice(existing.id);
          if (mounted) {
            setState(() {
              _items
                ..clear()
                ..addAll(
                  apiItems.map((raw) {
                    return _editableItemFromJson(raw as Map<String, dynamic>);
                  }),
                );
            });
          }
        } catch (_) {
          // Keep the already populated items if the refresh fails.
        } finally {
          if (mounted) setState(() => _loadingItems = false);
        }
      });
    } else {
      // Create mode
      if (widget.preselectedCustomerId != null) {
        _selectedCustomerId = widget.preselectedCustomerId;
        _selectedCustomerName = widget.preselectedCustomerName ?? '';
      }
      Future.microtask(() async {
        ref.read(customerProvider.notifier).loadCustomers();
        ref.read(productProvider.notifier).loadProducts();
        final number = await ref
            .read(billingProvider.notifier)
            .getNextInvoiceNumber();
        if (mounted) _numberController.text = number;
      });
    }
    _taxController.addListener(_onTaxChanged);
  }

  void _onTaxChanged() {
    final parsed = double.tryParse(_taxController.text) ?? 0;
    if (parsed != _taxPercent) {
      setState(() => _taxPercent = parsed);
    }
  }

  @override
  void dispose() {
    _taxController.removeListener(_onTaxChanged);
    _numberController.dispose();
    _billNoController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(
    0,
    (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
  );
  double get _taxAmount => _subtotal * (_taxPercent / 100);
  double get _total => _subtotal + _taxAmount;

  double _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _editableItemFromInvoiceItem(InvoiceItem item) {
    return {
      'product_id': item.productId,
      'product_name': item.productName ?? item.description ?? 'Item',
      'description': item.description ?? item.productName ?? '',
      'quantity': item.quantity,
      'unit': item.unit,
      'selling_rate_per_unit': item.sellingRatePerUnit,
      'amount': item.amount,
    };
  }

  Map<String, dynamic> _editableItemFromJson(Map<String, dynamic> item) {
    final productName = item['product_name']?.toString();
    final description = item['description']?.toString();
    return {
      'product_id': _intOrNull(item['product_id']),
      'product_name': (productName != null && productName.isNotEmpty)
          ? productName
          : (description != null && description.isNotEmpty
                ? description
                : 'Item'),
      'description': description ?? productName ?? '',
      'quantity': _num(item['quantity']),
      'unit': item['unit']?.toString() ?? 'brass',
      'selling_rate_per_unit': _num(item['selling_rate_per_unit']),
      'amount': _num(item['amount']),
    };
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.existingInvoice != null
                        ? Icons.edit_rounded
                        : Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.existingInvoice != null
                      ? 'Edit Invoice'
                      : 'Create Invoice',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice # and Bill No row
                  Row(
                    children: [
                      Expanded(
                        child: _inputContainer(
                          child: TextField(
                            controller: _numberController,
                            enabled: false,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            decoration: _inputDec(
                              'Invoice No.',
                              Icons.confirmation_number_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _inputContainer(
                          child: TextField(
                            controller: _billNoController,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDec(
                              'Bill No. (Manual)',
                              Icons.tag_rounded,
                              hint: 'e.g. 001, B-45',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dates row
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          'Invoice Date',
                          _invoiceDate,
                          _selectInvoiceDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dateTile(
                          'Due Date',
                          _dueDate,
                          _selectDueDate,
                          placeholder: 'Optional',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Customer selector
                  _label('Customer *'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _showCustomerSearch,
                    child: _inputContainer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 16,
                              color: _selectedCustomerName.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedCustomerName.isEmpty
                                    ? 'Tap to select customer…'
                                    : _selectedCustomerName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedCustomerName.isEmpty
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Items'),
                      GestureDetector(
                        onTap: _showAddProductDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add Product',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingItems)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Loading items...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 36,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No products added yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_items.length, (index) {
                      final item = _items[index];
                      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
                      final rate =
                          (item['selling_rate_per_unit'] as num?)?.toDouble() ??
                          0;
                      final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'] ??
                                        item['description'] ??
                                        'Item',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${qty.toStringAsFixed(1)} brass × ₹${rate.toStringAsFixed(0)}/brass',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${fmt.format(amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _items.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 15,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  // Tax + summary
                  Row(
                    children: [
                      _label('GST / Tax'),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 72,
                        child: _inputContainer(
                          child: TextField(
                            controller: _taxController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        _amtRow('Subtotal', _subtotal, fmt),
                        if (_taxPercent > 0) ...[
                          const SizedBox(height: 6),
                          _amtRow(
                            'GST (${_taxPercent.toStringAsFixed(1)}%)',
                            _taxAmount,
                            fmt,
                          ),
                        ],
                        const Divider(height: 16, color: AppColors.border),
                        _amtRow('Total', _total, fmt, bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('Notes'),
                  const SizedBox(height: 6),
                  _inputContainer(
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDec(
                        'Optional notes...',
                        Icons.notes_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Submit button
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.3,
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.existingInvoice != null
                            ? 'UPDATE INVOICE'
                            : 'CREATE INVOICE',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedCustomerId == null) {
      _snack('Please select a customer first', AppColors.warning);
      return;
    }
    if (_items.isEmpty) {
      _snack('Please add at least one product', AppColors.warning);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSave({
        'invoice_number': _numberController.text,
        'bill_no': _billNoController.text.isEmpty
            ? null
            : _billNoController.text,
        'customer_id': _selectedCustomerId,
        'invoice_date': billingDateParam(_invoiceDate),
        'due_date': _dueDate != null ? billingDateParam(_dueDate!) : null,
        'subtotal': _subtotal,
        'tax_amount': _taxAmount,
        'total_amount': _total,
        'status': 'pending',
        'notes': _notesController.text,
        'items': _items,
      });
    } catch (e) {
      if (mounted) _snack('Failed: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
    ),
  );

  Widget _inputContainer({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  InputDecoration _inputDec(
    String label,
    IconData icon, {
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    isDense: true,
  );

  Widget _dateTile(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    String? placeholder,
  }) => GestureDetector(
    onTap: onTap,
    child: _inputContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    date == null
                        ? (placeholder ?? 'Select')
                        : DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: date == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: date == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _amtRow(
    String label,
    double amount,
    NumberFormat fmt, {
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '₹${fmt.format(amount)}',
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  void _selectInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: billingTodayIstDate().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _invoiceDate = picked);
  }

  void _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _invoiceDate.add(const Duration(days: 30)),
      firstDate: _invoiceDate,
      lastDate: billingTodayIstDate().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _showCustomerSearch() {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Select Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  ref.read(customerProvider.notifier).searchCustomers(value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final customerState = ref.watch(customerProvider);
                  final customers = searchController.text.isEmpty
                      ? customerState.customers
                      : customerState.searchResults;
                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text('No customers found'),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(customer.name[0].toUpperCase()),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.customerCode} â€¢ ${customer.phone ?? "No phone"}',
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCustomerId = customer.id;
                            _selectedCustomerName = customer.name;
                          });
                          Navigator.pop(bottomSheetContext);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => AddProductSheet(
        onAdd: (productData) {
          setState(() {
            _items.add(productData);
          });
          Navigator.pop(bottomSheetContext);
        },
      ),
    );
  }
}

class AddProductSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AddProductSheet({super.key, required this.onAdd});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  int? _selectedProductId;
  String _selectedProductName = '';
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productProvider.notifier).loadProducts());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _amount =>
      (double.tryParse(_quantityController.text) ?? 0) *
      (double.tryParse(_rateController.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final fmt = NumberFormat('#,##,###');
    final canAdd =
        _selectedProductId != null &&
        _quantityController.text.isNotEmpty &&
        _rateController.text.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Product selector
            GestureDetector(
              onTap: () => _showProductSelector(productState.products),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedProductId != null
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: _selectedProductId != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedProductName.isEmpty
                            ? 'Tap to select product'
                            : _selectedProductName,
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedProductName.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: _selectedProductName.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Qty + Rate
            Row(
              children: [
                Expanded(
                  child: _numField(
                    _quantityController,
                    'Quantity (brass)',
                    Icons.scale_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numField(
                    _rateController,
                    'Rate / brass',
                    Icons.currency_rupee_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calculated Amount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\u20b9${fmt.format(_amount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Description (optional)...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAdd
                    ? () => widget.onAdd({
                        'product_id': _selectedProductId,
                        'product_name': _selectedProductName,
                        'description': _descriptionController.text.isEmpty
                            ? _selectedProductName
                            : _descriptionController.text,
                        'quantity':
                            double.tryParse(_quantityController.text) ?? 0,
                        'selling_rate_per_unit':
                            double.tryParse(_rateController.text) ?? 0,
                        'amount': _amount,
                      })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accent.withValues(
                    alpha: 0.3,
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ADD TO INVOICE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    ValueChanged<String>? onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged ?? (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
    ),
  );

  void _showProductSelector(List products) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select Product',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${p.sizeMm ?? "?"}mm',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${p.productCode} | \u20b9${p.currentRate.toStringAsFixed(0)}/brass',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedProductId = p.id;
                              _selectedProductName = p.name;
                              if (_rateController.text.isEmpty) {
                                _rateController.text = p.currentRate
                                    .toStringAsFixed(0);
                              }
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
