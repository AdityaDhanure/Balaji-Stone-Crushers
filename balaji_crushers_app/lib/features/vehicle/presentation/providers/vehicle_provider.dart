import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

String _mapValue(dynamic item, List<String> keys) {
  if (item is! Map) return '';
  for (final key in keys) {
    final value = item[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
}

int _mapId(dynamic item) {
  if (item is! Map) return 0;
  return int.tryParse(item['id']?.toString() ?? '') ?? 0;
}

int _compareVehicleMaps(dynamic a, dynamic b) {
  final byNumber = _mapValue(a, ['vehicle_number']).toLowerCase().compareTo(
        _mapValue(b, ['vehicle_number']).toLowerCase(),
      );
  if (byNumber != 0) return byNumber;
  return _mapId(a).compareTo(_mapId(b));
}

int _compareUsageNewestFirst(dynamic a, dynamic b) {
  final byDate = _mapValue(b, ['usage_date', 'date', 'created_at']).compareTo(
    _mapValue(a, ['usage_date', 'date', 'created_at']),
  );
  if (byDate != 0) return byDate;
  return _mapId(b).compareTo(_mapId(a));
}

class VehicleState {
  final bool isLoading;
  final List<dynamic> vehicles;
  final Map<String, dynamic>? selectedVehicle;
  final List<dynamic> expiringDocuments;
  final List<dynamic> usageRecords;
  final List<dynamic> dateGroupedUsage;
  final List<dynamic> usageDates;
  final String? error;

  const VehicleState({
    this.isLoading = false,
    this.vehicles = const [],
    this.selectedVehicle,
    this.expiringDocuments = const [],
    this.usageRecords = const [],
    this.dateGroupedUsage = const [],
    this.usageDates = const [],
    this.error,
  });

  VehicleState copyWith({
    bool? isLoading,
    List<dynamic>? vehicles,
    Map<String, dynamic>? selectedVehicle,
    List<dynamic>? expiringDocuments,
    List<dynamic>? usageRecords,
    List<dynamic>? dateGroupedUsage,
    List<dynamic>? usageDates,
    String? error,
  }) {
    return VehicleState(
      isLoading: isLoading ?? this.isLoading,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      expiringDocuments: expiringDocuments ?? this.expiringDocuments,
      usageRecords: usageRecords ?? this.usageRecords,
      dateGroupedUsage: dateGroupedUsage ?? this.dateGroupedUsage,
      usageDates: usageDates ?? this.usageDates,
      error: error ?? this.error,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleRepository _repository;

  VehicleNotifier(this._repository) : super(const VehicleState());

  Future<void> loadVehicles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vehicles = (await _repository.getAllVehicles())
        ..sort(_compareVehicleMaps);
      state = state.copyWith(isLoading: false, vehicles: vehicles);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadExpiringDocuments() async {
    try {
      final expiring = await _repository.getUpcomingExpiries();
      state = state.copyWith(expiringDocuments: expiring);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadVehicleDetails(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 🔹 STEP 1: Load vehicle FIRST
      final vehicle = await _repository.getVehicleById(id);

      // 🔹 STEP 2: Update UI immediately
      state = state.copyWith(
        selectedVehicle: vehicle,
        isLoading: false,
      );

      // 🔹 STEP 3: Load usage in background
      final usage = (await _repository.getVehicleUsage(id))
        ..sort(_compareUsageNewestFirst);

      // 🔹 STEP 4: Update usage separately
      state = state.copyWith(usageRecords: usage);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createVehicle(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createVehicle(data);
      await loadVehicles();
      await loadExpiringDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateVehicle(id, data);
      await loadVehicles();
      await loadExpiringDocuments();
      if (state.selectedVehicle?['id'] == id) {
        await loadVehicleDetails(id);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteVehicle(id);
      await loadVehicles();
      await loadExpiringDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> addUsage(Map<String, dynamic> data) async {
    try {
      await _repository.addUsage(data);
      if (state.selectedVehicle != null) {
        await loadVehicleDetails(state.selectedVehicle!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteUsage(int id) async {
    try {
      await _repository.deleteUsage(id);
      if (state.selectedVehicle != null) {
        await loadVehicleDetails(state.selectedVehicle!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateOdometer(int id, double reading) async {
    try {
      await _repository.updateOdometer(id, reading);
      await loadVehicleDetails(id);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearSelectedVehicle() {
    state = state.copyWith(selectedVehicle: null, usageRecords: []);
  }

  Future<List<dynamic>> getUsageGroupedByDate(int vehicleId) async {
    try {
      return (await _repository.getUsageGroupedByDate(vehicleId))
        ..sort(_compareUsageNewestFirst);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  Future<List<dynamic>> getUsageDates(int vehicleId) async {
    try {
      return (await _repository.getUsageDates(vehicleId))
        ..sort((a, b) => b.toString().compareTo(a.toString()));
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  Future<bool> updateUsage(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateUsage(id, data);
      if (state.selectedVehicle != null) {
        await loadVehicleDetails(state.selectedVehicle!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final notifier = VehicleNotifier(ref.read(vehicleRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (previous, next) {
    notifier.loadVehicles();
  });
  return notifier;
});
