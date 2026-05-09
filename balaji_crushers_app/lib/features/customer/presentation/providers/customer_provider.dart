import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerState {
  final bool isLoading;
  final List<Customer> customers;
  final List<Customer> searchResults;
  final CustomerWallet? wallet;
  final String? error;

  const CustomerState({
    this.isLoading = false,
    this.customers = const [],
    this.searchResults = const [],
    this.wallet,
    this.error,
  });

  CustomerState copyWith({
    bool? isLoading,
    List<Customer>? customers,
    List<Customer>? searchResults,
    CustomerWallet? wallet,
    String? error,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      customers: customers ?? this.customers,
      searchResults: searchResults ?? this.searchResults,
      wallet: wallet ?? this.wallet,
      error: error,
    );
  }
}

class Customer {
  final int id;
  final String customerCode;
  final String name;
  final String customerType;
  final String? email;
  final String? phone;
  final String? alternatePhone;
  final String? gstNumber;
  final String? panNumber;
  final String? billingAddress;
  final String? shippingAddress;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final String? notes;

  const Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    this.customerType = 'individual',
    this.email,
    this.phone,
    this.alternatePhone,
    this.gstNumber,
    this.panNumber,
    this.billingAddress,
    this.shippingAddress,
    this.city,
    this.district,
    this.state,
    this.pincode,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.isActive = true,
    this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      customerCode: json['customer_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      customerType: json['customer_type']?.toString() ?? 'individual',

      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      alternatePhone: json['alternate_phone']?.toString(),
      gstNumber: json['gst_number']?.toString(),
      panNumber: json['pan_number']?.toString(),

      billingAddress: json['billing_address']?.toString(),
      shippingAddress: json['shipping_address']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),

      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '0') ?? 0,
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0,

      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == 't' ||
          json['is_active'] == 'true',

      notes: json['notes']?.toString(),
    );
  }

  String get typeDisplay {
    switch (customerType) {
      case 'company':
        return 'Company';
      case 'government':
        return 'Government';
      default:
        return 'Individual';
    }
  }

  String get fullAddress {
    final parts = <String>[];
    if (billingAddress != null && billingAddress!.isNotEmpty) parts.add(billingAddress!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }
}

class WalletTransaction {
  final int id;
  final int customerId;
  final String transactionType;
  final double amount;
  final String? paymentMode;
  final String? referenceNumber;
  final String transactionDate;
  final String? description;
  final String? createdByName;

  const WalletTransaction({
    required this.id,
    required this.customerId,
    required this.transactionType,
    required this.amount,
    this.paymentMode,
    this.referenceNumber,
    required this.transactionDate,
    this.description,
    this.createdByName,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      customerId: int.tryParse(json['customer_id']?.toString() ?? '') ?? 0,

      transactionType: json['transaction_type']?.toString() ?? '',

      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,

      paymentMode: json['payment_mode']?.toString(),
      referenceNumber: json['reference_number']?.toString(),
      transactionDate: json['transaction_date']?.toString() ?? '',
      description: json['description']?.toString(),
      createdByName: json['created_by_name']?.toString(),
    );
  }

  bool get isCredit => transactionType == 'credit';
}

class CustomerWallet {
  final List<WalletTransaction> transactions;
  final double balance;

  const CustomerWallet({
    this.transactions = const [],
    this.balance = 0,
  });

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    final txList = (json['transactions'] as List<dynamic>?)
        ?.map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>))
        .toList() ?? [];
    return CustomerWallet(
      transactions: txList,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const CustomerState());

  Future<void> loadCustomers() async {
    try {
      final data = await _repository.getCustomers();

      final customers = data
          .map((c) => Customer.fromJson(c as Map<String, dynamic>))
          .toList();

      state = state.copyWith(customers: customers);
      } catch (e) {
        state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadActiveCustomers() async {
    try {
      final data = await _repository.getActiveCustomers();
      final customers = data.map((c) => Customer.fromJson(c as Map<String, dynamic>)).toList();
      state = state.copyWith(customers: customers);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createCustomer(data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateCustomer(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateCustomer(id, data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> getNextCustomerCode() async {
    try {
      return await _repository.getNextCustomerCode();
    } catch (e) {
      return 'CUST-001';
    }
  }

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    try {
      final data = await _repository.searchCustomers(query);
      final customers = data.map((c) => Customer.fromJson(c as Map<String, dynamic>)).toList();
      state = state.copyWith(searchResults: customers);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadWallet(int customerId) async {
    try {
      final data = await _repository.getWalletData(customerId);
      state = state.copyWith(wallet: CustomerWallet.fromJson(data));
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.addWalletTransaction(data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadAllData() async {
    print("LOAD ALL DATA...............11111111111111");
    state = state.copyWith(isLoading: true, error: null);

    try {
      await loadCustomers();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final notifier = CustomerNotifier(ref.read(customerRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (_, __) {
    notifier.loadAllData();
  });
  return notifier;
});
