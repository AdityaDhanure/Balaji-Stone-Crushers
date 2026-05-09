import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/diesel_repository.dart';
import '../../utils/diesel_date_utils.dart';

final dieselRepositoryProvider = Provider<DieselRepository>((ref) {
  return DieselRepository();
});

class DieselState {
  final bool isLoading;
  final DieselStockOverview stockOverview;
  final List<DieselPurchase> purchases;
  final List<DieselConsumption> consumption;
  final List<Map<String, dynamic>> dateGroupedConsumption;
  final List<VehicleSimple> vehicles;
  final List<PumpWisePayment> pumpPayments;
  final String? error;

  const DieselState({
    this.isLoading = false,
    this.stockOverview = const DieselStockOverview(),
    this.purchases = const [],
    this.consumption = const [],
    this.dateGroupedConsumption = const [],
    this.vehicles = const [],
    this.pumpPayments = const [],
    this.error,
  });

  DieselState copyWith({
    bool? isLoading,
    DieselStockOverview? stockOverview,
    List<DieselPurchase>? purchases,
    List<DieselConsumption>? consumption,
    List<Map<String, dynamic>>? dateGroupedConsumption,
    List<VehicleSimple>? vehicles,
    List<PumpWisePayment>? pumpPayments,
    String? error,
  }) {
    return DieselState(
      isLoading: isLoading ?? this.isLoading,
      stockOverview: stockOverview ?? this.stockOverview,
      purchases: purchases ?? this.purchases,
      consumption: consumption ?? this.consumption,
      dateGroupedConsumption: dateGroupedConsumption ?? this.dateGroupedConsumption,
      vehicles: vehicles ?? this.vehicles,
      pumpPayments: pumpPayments ?? this.pumpPayments,
      error: error,
    );
  }
}

class DieselStockOverview {
  final double totalPurchased;
  final double totalConsumed;
  final double currentStock;
  final double pendingPayments;
  final double totalPaid;

  const DieselStockOverview({
    this.totalPurchased = 0,
    this.totalConsumed = 0,
    this.currentStock = 0,
    this.pendingPayments = 0,
    this.totalPaid = 0,
  });

  factory DieselStockOverview.fromJson(Map<String, dynamic> json) {
    return DieselStockOverview(
      totalPurchased: double.tryParse(json['total_purchased']?.toString() ?? '0') ?? 0,
      totalConsumed: double.tryParse(json['total_consumed']?.toString() ?? '0') ?? 0,
      currentStock: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0,
      pendingPayments: double.tryParse(json['pending_payments']?.toString() ?? '0') ?? 0,
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
    );
  }
}

class DieselPurchase {
  final int id;
  final String pumpName;
  final double quantity;
  final double ratePerLiter;
  final double totalAmount;
  final String paymentStatus;
  final String purchaseDate;
  final String? remarks;

  const DieselPurchase({
    required this.id,
    required this.pumpName,
    required this.quantity,
    required this.ratePerLiter,
    required this.totalAmount,
    required this.paymentStatus,
    required this.purchaseDate,
    this.remarks,
  });

  factory DieselPurchase.fromJson(Map<String, dynamic> json) {
    return DieselPurchase(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      pumpName: json['pump_name']?.toString() ?? '',

      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      ratePerLiter: double.tryParse(json['rate_per_liter']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,

      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      purchaseDate: dieselDateString(json['purchase_date']),
      remarks: json['remarks']?.toString(),
    );
  }

  bool get isPaid => paymentStatus == 'paid';
}

class DieselConsumption {
  final int id;
  final int vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final double quantity;
  final String consumptionDate;
  final String? purpose;
  final String? remarks;

  const DieselConsumption({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.quantity,
    required this.consumptionDate,
    this.purpose,
    this.remarks,
  });

  factory DieselConsumption.fromJson(Map<String, dynamic> json) {
    return DieselConsumption(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vehicleId: int.tryParse(json['vehicle_id']?.toString() ?? '') ?? 0,

      vehicleNumber: json['vehicle_number']?.toString() ?? 'Unknown',
      vehicleType: json['vehicle_type']?.toString() ?? '',

      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,

      consumptionDate: dieselDateString(json['consumption_date']),

      purpose: json['purpose']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }
}

class VehicleSimple {
  final int id;
  final String vehicleNumber;
  final String vehicleType;

  const VehicleSimple({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
  });

  factory VehicleSimple.fromJson(Map<String, dynamic> json) {
    return VehicleSimple(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
    );
  }
}

class PumpWisePayment {
  final String pumpName;
  final int purchases;
  final double totalQuantity;
  final double totalAmount;

  const PumpWisePayment({
    required this.pumpName,
    required this.purchases,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory PumpWisePayment.fromJson(Map<String, dynamic> json) {
    return PumpWisePayment(
       pumpName: json['pump_name']?.toString() ?? '',

      purchases: int.tryParse(json['purchases']?.toString() ?? '0') ?? 0,

      totalQuantity: double.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class DieselNotifier extends StateNotifier<DieselState> {
  final DieselRepository _repository;

  DieselNotifier(this._repository) : super(const DieselState());

  Future<void> loadStockOverview() async {
    try {
      final overview = await _repository.getStockOverview();
      state = state.copyWith(stockOverview: DieselStockOverview.fromJson(overview));
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadPurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getAllPurchases();
      final purchases = data.map((p) => DieselPurchase.fromJson(p as Map<String, dynamic>)).toList();
      state = state.copyWith(purchases: purchases);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadConsumption() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getAllConsumption();
      final consumption = data.map((c) => DieselConsumption.fromJson(c as Map<String, dynamic>)).toList();
      state = state.copyWith(consumption: consumption);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadVehicles() async {
    try {
      final data = await _repository.getVehicles();
      final vehicles = data.map((v) => VehicleSimple.fromJson(v as Map<String, dynamic>)).toList();
      state = state.copyWith(vehicles: vehicles);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadPumpWisePayments() async {
    try {
      final data = await _repository.getPumpWisePayments();
      final payments = data.map((p) => PumpWisePayment.fromJson(p as Map<String, dynamic>)).toList();
      state = state.copyWith(pumpPayments: payments);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createPurchase(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createPurchase(data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deletePurchase(int id) async {
    try {
      await _repository.deletePurchase(id);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> markPurchasePaid(int id) async {
     try {
      await _repository.markPurchasePaid(id);
      await loadPurchases();
      await loadStockOverview(); // 🔥 ADD THIS LINE
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> createConsumption(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createConsumption(data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteConsumption(int id) async {
    try {
      await _repository.deleteConsumption(id);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateConsumption(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateConsumption(id, data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getConsumptionGroupedByDate() async {
    try {
      final data = await _repository.getConsumptionGroupedByDate();
      return data.map((d) => d as Map<String, dynamic>).toList();
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return [];
    }
  }

  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await loadStockOverview();
      await loadPurchases();
      await loadConsumption();
      await loadVehicles();
      await loadPumpWisePayments();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final dieselProvider = StateNotifierProvider<DieselNotifier, DieselState>((ref) {
  final notifier = DieselNotifier(ref.read(dieselRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (previous, next) {
    notifier.loadAllData();
  });
  return notifier;
});
