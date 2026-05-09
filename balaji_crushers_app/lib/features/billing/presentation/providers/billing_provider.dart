import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/billing_repository.dart';
import '../../utils/billing_date_utils.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository();
});

class BillingState {
  final bool isLoading;
  final List<Invoice> invoices;
  final InvoiceStats? stats;
  final String? error;

  const BillingState({
    this.isLoading = false,
    this.invoices = const [],
    this.stats,
    this.error,
  });

  BillingState copyWith({
    bool? isLoading,
    List<Invoice>? invoices,
    InvoiceStats? stats,
    String? error,
  }) {
    return BillingState(
      isLoading: isLoading ?? this.isLoading,
      invoices: invoices ?? this.invoices,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

class InvoiceStats {
  final int totalInvoices;
  final double totalValue;
  final double totalCollected;
  final double totalPending;
  final int paidCount;
  final int pendingCount;
  final int partialCount;

  const InvoiceStats({
    this.totalInvoices = 0,
    this.totalValue = 0,
    this.totalCollected = 0,
    this.totalPending = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
    this.partialCount = 0,
  });

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    return InvoiceStats(
      totalInvoices: int.tryParse(json['total_invoices']?.toString() ?? '0') ?? 0,

      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0,
      totalCollected: double.tryParse(json['total_collected']?.toString() ?? '0') ?? 0,
      totalPending: double.tryParse(json['total_pending']?.toString() ?? '0') ?? 0,

      paidCount: int.tryParse(json['paid_count']?.toString() ?? '0') ?? 0,
      pendingCount: int.tryParse(json['pending_count']?.toString() ?? '0') ?? 0,
      partialCount: int.tryParse(json['partial_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class Invoice {
  final int id;
  final String invoiceNumber;
  final String? billNo;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerGst;
  final String? customerCity;
  final String invoiceDate;
  final String? dueDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double amountPaid;
  final String status;
  final String? notes;
  final String? terms;
  final String? createdByName;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.billNo,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerGst,
    this.customerCity,
    required this.invoiceDate,
    this.dueDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.amountPaid = 0,
    this.status = 'draft',
    this.notes,
    this.terms,
    this.createdByName,
    this.items = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
        ?.map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>))
        .toList() ?? [];

    return Invoice(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      invoiceNumber: json['invoice_number']?.toString() ?? '',
      billNo: json['bill_no']?.toString(),

      customerId: int.tryParse(json['customer_id']?.toString() ?? ''),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      customerGst: json['customer_gst']?.toString(),
      customerCity: json['customer_city']?.toString(),

      invoiceDate: billingDateString(json['invoice_date']),
      dueDate:
          json['due_date'] == null ? null : billingDateString(json['due_date']),

      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      amountPaid: double.tryParse(json['amount_paid']?.toString() ?? '0') ?? 0,

      status: json['status']?.toString() ?? 'draft',
      notes: json['notes']?.toString(),
      terms: json['terms']?.toString(),
      createdByName: json['created_by_name']?.toString(),

      items: itemsList,
    );
  }

  double get balanceDue => totalAmount - amountPaid;

  String get statusDisplay {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'partial':
        return 'Partial';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Draft';
    }
  }
}

class InvoiceItem {
  final int id;
  final int? invoiceId;
  final int? productId;
  final String? productName;
  final String? productCode;
  final int? sizeMm;
  final String? description;
  final double quantity;
  final String unit;
  final double sellingRatePerUnit;
  final double amount;

  const InvoiceItem({
    required this.id,
    this.invoiceId,
    this.productId,
    this.productName,
    this.productCode,
    this.sizeMm,
    this.description,
    required this.quantity,
    this.unit = 'brass',
    required this.sellingRatePerUnit,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      invoiceId: int.tryParse(json['invoice_id']?.toString() ?? ''),
      productId: int.tryParse(json['product_id']?.toString() ?? ''),

      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),

      sizeMm: int.tryParse(json['size_mm']?.toString() ?? ''),

      description: json['description']?.toString(),

      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString() ?? 'brass',
      sellingRatePerUnit: double.tryParse(json['selling_rate_per_unit']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class InvoicePayment {
  final int id;
  final int invoiceId;
  final double amount;
  final String paymentMode;
  final String? referenceNumber;
  final String paymentDate;
  final String? notes;
  final String? createdByName;

  const InvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    this.createdByName,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      invoiceId: int.tryParse(json['invoice_id']?.toString() ?? '') ?? 0,

      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,

      paymentMode: json['payment_mode']?.toString() ?? 'cash',
      referenceNumber: json['reference_number']?.toString(),

      paymentDate: billingDateString(json['payment_date']),
      notes: json['notes']?.toString(),
      createdByName: json['created_by_name']?.toString(),
    );
  }

  String get paymentModeDisplay {
    switch (paymentMode) {
      case 'cash': return '💵 Cash';
      case 'bank_transfer': return '🏦 Bank Transfer';
      case 'cheque': return '📝 Cheque';
      case 'rtgs': return '⚡ RTGS/NEFT';
      case 'upi': return '📱 UPI';
      default: return paymentMode;
    }
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingRepository _repository;

  BillingNotifier(this._repository) : super(const BillingState());

  Future<void> loadInvoices({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getInvoices(status: status);
      final invoices = data.map((i) => Invoice.fromJson(i as Map<String, dynamic>)).toList();
      state = state.copyWith(invoices: invoices);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadStats() async {
    try {
      final data = await _repository.getInvoiceStats();
      state = state.copyWith(stats: InvoiceStats.fromJson(data), isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createInvoice(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createInvoice(data);
      await loadInvoices();
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateInvoiceStatus(int id, String status) async {
    try {
      await _repository.updateInvoiceStatus(id, status);
      await loadInvoices();
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateInvoice(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateInvoice(id, data);
      await loadInvoices();
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteInvoice(int id) async {
    try {
      await _repository.deleteInvoice(id);
      await loadInvoices();
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> getNextInvoiceNumber() async {
    try {
      return await _repository.getNextInvoiceNumber();
    } catch (e) {
      return 'INV-${billingNowIst().year}-0001';
    }
  }

  Future<bool> recordPayment(
    int invoiceId,
    double amount,
    String paymentMode, {
    String? reference,
    DateTime? paymentDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.recordPayment({
        'invoice_id': invoiceId,
        'amount': amount,
        'payment_mode': paymentMode,
        'reference_number': reference,
        'payment_date': billingDateParam(paymentDate ?? billingTodayIstDate()),
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await loadInvoices();
      await loadStats();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  final notifier = BillingNotifier(ref.read(billingRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (previous, next) {
    notifier.loadAllData();
  });
  return notifier;
});
