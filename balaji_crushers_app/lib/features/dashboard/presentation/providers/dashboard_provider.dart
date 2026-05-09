import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../blast/presentation/providers/blast_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class DashboardStats {
  final int activeBlasts;
  final int totalVehicles;
  final int totalCustomers;
  final double pendingBills;
  final bool isLoading;

  const DashboardStats({
    this.activeBlasts = 0,
    this.totalVehicles = 0,
    this.totalCustomers = 0,
    this.pendingBills = 0,
    this.isLoading = true,
  });

  DashboardStats copyWith({
    int? activeBlasts,
    int? totalVehicles,
    int? totalCustomers,
    double? pendingBills,
    bool? isLoading,
  }) => DashboardStats(
    activeBlasts: activeBlasts ?? this.activeBlasts,
    totalVehicles: totalVehicles ?? this.totalVehicles,
    totalCustomers: totalCustomers ?? this.totalCustomers,
    pendingBills: pendingBills ?? this.pendingBills,
    isLoading: isLoading ?? this.isLoading,
  );
}

class DashboardNotifier extends StateNotifier<DashboardStats> {
  final Ref _ref;
  DashboardNotifier(this._ref) : super(const DashboardStats());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);

    // Load all in parallel — vehicles + customers + blasts + billing stats + billing invoices
    await Future.wait([
      _ref.read(blastProvider.notifier).loadBlasts(),
      _ref.read(blastProvider.notifier).loadActiveBlast(),
      _ref.read(vehicleProvider.notifier).loadVehicles(),
      _ref.read(customerProvider.notifier).loadCustomers(),
      _ref.read(billingProvider.notifier).loadInvoices(),
      _ref.read(billingProvider.notifier).loadStats(),
    ]);

    _aggregate();
  }

  void _aggregate() {
    final blastState = _ref.read(blastProvider);
    final vehicleState = _ref.read(vehicleProvider);
    final customerState = _ref.read(customerProvider);
    final billingState = _ref.read(billingProvider);

    final activeBlasts = blastState.blasts.where((b) => b['status'] == 'active').length;
    final totalVehicles = vehicleState.vehicles.length;
    final totalCustomers = customerState.customers.length;
    final pendingBills = billingState.stats?.totalPending ?? 0.0;

    state = state.copyWith(
      activeBlasts: activeBlasts,
      totalVehicles: totalVehicles,
      totalCustomers: totalCustomers,
      pendingBills: pendingBills,
      isLoading: false,
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
  return DashboardNotifier(ref);
});
