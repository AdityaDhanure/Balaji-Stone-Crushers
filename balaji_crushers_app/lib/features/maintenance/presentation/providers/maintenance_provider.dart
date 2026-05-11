import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../../data/maintenance_repository.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  return int.tryParse(val.toString()) ?? 0;
}

bool _toBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    final v = val.toLowerCase();
    return v == 'true' || v == '1' || v == 't';
  }
  return false;
}

int _compareMaintenanceNewestFirst(MaintenanceRecord a, MaintenanceRecord b) {
  final byDate = b.maintenanceDate.compareTo(a.maintenanceDate);
  if (byDate != 0) return byDate;
  return b.id.compareTo(a.id);
}

int _compareEquipmentByName(Equipment a, Equipment b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}

int _compareVendorsByName(Vendor a, Vendor b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}

int _comparePartsByName(SparePart a, SparePart b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});

class MaintenanceState {
  final String filter;
  final bool isLoading;
  final List<MaintenanceRecord> records;
  final List<Equipment> equipment;
  final List<MaintenanceRecord> dueSoon;
  final MaintenanceStats? stats;
  final List<Vendor> vendors;
  final List<SparePart> parts;
  final String? error;

  const MaintenanceState({
    this.filter = 'all',
    this.isLoading = false,
    this.records = const [],
    this.equipment = const [],
    this.dueSoon = const [],
    this.stats,
    this.vendors = const [],
    this.parts = const [],
    this.error,
  });

  MaintenanceState copyWith({
    String? filter,
    bool? isLoading,
    List<MaintenanceRecord>? records,
    List<Equipment>? equipment,
    List<MaintenanceRecord>? dueSoon,
    MaintenanceStats? stats,
    List<Vendor>? vendors,
    List<SparePart>? parts,
    String? error,
  }) {
    return MaintenanceState(
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      equipment: equipment ?? this.equipment,
      dueSoon: dueSoon ?? this.dueSoon,
      stats: stats ?? this.stats,
      vendors: vendors ?? this.vendors,
      parts: parts ?? this.parts,
      error: error,
    );
  }
}

class MaintenanceStats {
  final int totalRecords;
  final double totalCost;
  final int pendingCount;
  final int inProgressCount;
  final int dueSoonCount;

  const MaintenanceStats({
    this.totalRecords = 0,
    this.totalCost = 0,
    this.pendingCount = 0,
    this.inProgressCount = 0,
    this.dueSoonCount = 0,
  });

  factory MaintenanceStats.fromJson(Map<String, dynamic> json) {
    return MaintenanceStats(
      totalRecords: _toInt(json['total_records']),
      totalCost: _toDouble(json['total_cost']),
      pendingCount: _toInt(json['pending_count']),
      inProgressCount: _toInt(json['in_progress_count']),
      dueSoonCount: _toInt(json['due_soon_count']),
    );
  }
}

class MaintenanceRecord {
  final int id;
  final int? equipmentId;
  final int? vehicleId;
  final String? equipmentName;
  final String? vehicleNumber;
  final String maintenanceType;
  final String description;
  final String maintenanceDate;
  final String? nextDueDate;
  final double cost;
  final String? vendorName;
  final String? vendorPhone;
  final String? partsReplaced;
  final String status;
  final String? createdByName;
  final String? vehicleType;

  const MaintenanceRecord({
    required this.id,
    this.equipmentId,
    this.vehicleId,
    this.equipmentName,
    this.vehicleNumber,
    required this.maintenanceType,
    required this.description,
    required this.maintenanceDate,
    this.nextDueDate,
    this.cost = 0,
    this.vendorName,
    this.vendorPhone,
    this.partsReplaced,
    this.status = 'completed',
    this.createdByName,
    this.vehicleType,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: _toInt(json['id']),
      equipmentId: _toInt(json['equipment_id']),
      vehicleId: _toInt(json['vehicle_id']),
      equipmentName: json['equipment_name']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
      maintenanceType: json['maintenance_type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      maintenanceDate: json['maintenance_date']?.toString() ?? '',
      nextDueDate: json['next_due_date']?.toString(),
      cost: _toDouble(json['cost']),
      vendorName: json['vendor_name']?.toString(),
      vendorPhone: json['vendor_phone']?.toString(),
      partsReplaced: json['parts_replaced']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      createdByName: json['created_by_name']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
    );
  }

  String get typeDisplay {
    if (equipmentName != null) return equipmentName!;
    if (vehicleNumber != null) return vehicleNumber!;
    return 'Unknown';
  }

  String get maintenanceTypeDisplay {
    switch (maintenanceType) {
      case 'repair':
        return 'Repair';
      case 'service':
        return 'Service';
      case 'inspection':
        return 'Inspection';
      case 'oil_change':
        return 'Oil Change';
      case 'replacement':
        return 'Part Replacement';
      default:
        return maintenanceType;
    }
  }

  bool get isOverdue {
    if (nextDueDate == null) return false;
    final parsed = appParseIstDate(nextDueDate);
    return parsed != null && parsed.isBefore(appTodayIstDate());
  }
}

class Equipment {
  final int id;
  final String name;
  final String equipmentType;
  final String equipmentPhase;
  final String code;
  final String? description;
  final String? purchaseDate;
  final String? warrantyExpiry;
  final bool isActive;
  final int totalMaintenances;
  final double totalSpent;

  const Equipment({
    required this.id,
    required this.name,
    this.equipmentType = 'crusher',
    this.equipmentPhase = 'primary',
    required this.code,
    this.description,
    this.purchaseDate,
    this.warrantyExpiry,
    this.isActive = true,
    this.totalMaintenances = 0,
    this.totalSpent = 0,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      equipmentType: json['equipment_type']?.toString() ?? 'crusher',
      equipmentPhase: json['equipment_phase']?.toString() ?? 'primary',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      purchaseDate: json['purchase_date']?.toString(),
      warrantyExpiry: json['warranty_expiry']?.toString(),
      isActive: _toBool(json['is_active']),
      totalMaintenances: _toInt(json['total_maintenances']),
      totalSpent: _toDouble(json['total_spent']),
    );
  }

  String get phaseDisplay {
    switch (equipmentPhase) {
      case 'primary': return 'Primary';
      case 'secondary': return 'Secondary';
      case 'tertiary': return 'Tertiary';
      case 'quaternary': return 'Quaternary';
      default: return 'Primary';
    }
  }

  String get typeDisplay {
    switch (equipmentType) {
      case 'crusher':
        return 'Crusher';
      case 'screen':
        return 'Screen';
      case 'conveyor':
        return 'Conveyor';
      case 'generator':
        return 'Generator';
      case 'hopper':
        return 'Hopper';
      default:
        return equipmentType;
    }
  }

  bool get isWarrantyExpired {
    if (warrantyExpiry == null) return false;
    final parsed = appParseIstDate(warrantyExpiry);
    return parsed != null && parsed.isBefore(appTodayIstDate());
  }
}

class Vendor {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? specialization;
  final bool isActive;

  const Vendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.specialization,
    this.isActive = true,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      specialization: json['specialization']?.toString(),
      isActive: _toBool(json['is_active']),
    );
  }
}

class SparePart {
  final int id;
  final String partNumber;
  final String name;
  final String? description;
  final String? category;
  final String unit;
  final int minStockLevel;
  final int currentStock;
  final double ratePerUnit;
  final bool isActive;
  final int totalUsed;

  const SparePart({
    required this.id,
    required this.partNumber,
    required this.name,
    this.description,
    this.category,
    this.unit = 'pcs',
    this.minStockLevel = 0,
    this.currentStock = 0,
    this.ratePerUnit = 0,
    this.isActive = true,
    this.totalUsed = 0,
  });

  factory SparePart.fromJson(Map<String, dynamic> json) {
    return SparePart(
      id: _toInt(json['id']),
      partNumber: json['part_number']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      unit: json['unit']?.toString() ?? 'pcs',
      minStockLevel: _toInt(json['min_stock_level']),
      currentStock: _toInt(json['current_stock']),
      ratePerUnit: _toDouble(json['rate_per_unit']),
      isActive: _toBool(json['is_active']),
      totalUsed: _toInt(json['total_used']),
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'transmission': return 'Transmission & Power Drive';
      case 'conveyor': return 'Conveyor System';
      case 'wear': return 'Machine Wear Parts';
      case 'electrical': return 'Maintenance & Electrical';
      default: return category ?? 'General';
    }
  }

  bool get isLowStock => currentStock <= minStockLevel;
}

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  final MaintenanceRepository _repository;

  MaintenanceNotifier(this._repository) : super(const MaintenanceState());

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }
  
  List<MaintenanceRecord> get filteredRecords {
    if (state.filter == 'all') return state.records;

    return state.records.where((r) {
      if (state.filter == 'equipment') {
        return r.equipmentId != null;
      }
      if (state.filter == 'vehicle') {
        return r.vehicleId != null;
      }
      return true;
    }).toList();
  }

  Future<void> loadRecords({String? type, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getMaintenanceRecords(type: type, status: status);
      final records = (data as List)
        .whereType<Map<String, dynamic>>()
        .map((r) => MaintenanceRecord.fromJson(r))
        .toList()
        ..sort(_compareMaintenanceNewestFirst);
      state = state.copyWith(isLoading: false, records: records);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadEquipment() async {
    try {
      final data = await _repository.getEquipment();

      final equipment = (data as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => Equipment.fromJson(e))
        .toList()
        ..sort(_compareEquipmentByName);

      state = state.copyWith(equipment: equipment);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadStats() async {
    try {
      final data = await _repository.getMaintenanceStats();
      if (data != null) {
        state = state.copyWith(stats: MaintenanceStats.fromJson(data));
      }
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createRecord(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Create the record on the backend
      await _repository.createMaintenance(data);
      // Reload full list — the create response lacks JOINed fields
      // (equipment_name, vendor_name, etc.) which causes "Unknown" display.
      await Future.wait([
        loadRecords(),
        loadStats(),
      ]);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateRecord(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Update on backend, then reload to get full joined fields
      await _repository.updateMaintenance(id, data);
      await Future.wait([
        loadRecords(),
        loadStats(),
      ]);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteRecord(int id, {bool recoverParts = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteMaintenanceWithRecovery(id, recoverParts);

      await Future.wait([
        loadRecords(),
        loadStats(),
      ]);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> createEquipment(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newData = await _repository.createEquipment(data);
      final newItem = Equipment.fromJson(newData);

      state = state.copyWith(
        isLoading: false,
        equipment: ([...state.equipment, newItem]..sort(_compareEquipmentByName)),
      );
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteEquipment(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteEquipment(id);

      state = state.copyWith(
        isLoading: false,
        equipment: state.equipment.where((e) => e.id != id).toList(),
      );
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> getNextEquipmentCode(String type) async {
    return await _repository.getNextEquipmentCode(type);
  }

  Future<bool> updateEquipment(int id, Map<String, dynamic> data) async {
    try {
      final updatedData = await _repository.updateEquipment(id, data);
      final updated = Equipment.fromJson(updatedData);

      state = state.copyWith(
        isLoading: false,
        equipment: (state.equipment.map((e) => e.id == id ? updated : e).toList()
          ..sort(_compareEquipmentByName)),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadVendors() async {
    try {
      final data = await _repository.getVendors();
      final vendors = (data as List)
        .whereType<Map<String, dynamic>>()
        .map((v) => Vendor.fromJson(v))
        .toList()
        ..sort(_compareVendorsByName);
      state = state.copyWith(vendors: vendors);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createVendor(Map<String, dynamic> data) async {
    try {
      final newData = await _repository.createVendor(data);
      final newItem = Vendor.fromJson(newData);

      state = state.copyWith(
        vendors: ([...state.vendors, newItem]..sort(_compareVendorsByName)),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteVendor(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteVendor(id);

      state = state.copyWith(
        isLoading: false,
        vendors: state.vendors.where((v) => v.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateVendor(int id, Map<String, dynamic> data) async {
    try {
      final updatedData = await _repository.updateVendor(id, data);
      final updated = Vendor.fromJson(updatedData);

      state = state.copyWith(
        vendors: (state.vendors.map((v) => v.id == id ? updated : v).toList()
          ..sort(_compareVendorsByName)),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadParts() async {
    if (state.parts.isNotEmpty) return; // prevent reload
    try {
      final data = await _repository.getParts();
      final parts = (data as List)
        .whereType<Map<String, dynamic>>()
        .map((p) => SparePart.fromJson(p))
        .toList()
        ..sort(_comparePartsByName);
      state = state.copyWith(parts: parts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createPart(Map<String, dynamic> data) async {
    try {
      final newData = await _repository.createPart(data);
      final newItem = SparePart.fromJson(newData);

      state = state.copyWith(
        parts: ([...state.parts, newItem]..sort(_comparePartsByName)),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deletePart(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deletePart(id);

      state = state.copyWith(
        isLoading: false,
        parts: state.parts.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updatePart(int id, Map<String, dynamic> data) async {
    try {
      final updatedData = await _repository.updatePart(id, data);
      final updated = SparePart.fromJson(updatedData);

      state = state.copyWith(
        parts: (state.parts.map((p) => p.id == id ? updated : p).toList()
          ..sort(_comparePartsByName)),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> getNextPartNumber() async {
    return await _repository.getNextPartNumber();
  }

  Future<List<MaintenanceRecord>> loadEquipmentRecords(int equipmentId) async {
    try {
      final data = await _repository.getRecordsByEquipment(equipmentId);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((r) => MaintenanceRecord.fromJson(r))
        .toList()
        ..sort(_compareMaintenanceNewestFirst);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return [];
    }
  }

  Future<void> loadAllData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load all data in parallel — records, stats, equipment and vendors
      // are all needed on the initial screen render.
      await Future.wait([
        loadRecords(),
        loadStats(),
        loadEquipment(),
        loadVendors(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  final notifier = MaintenanceNotifier(ref.read(maintenanceRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (_, __) {
    notifier.loadAllData();
  });
  return notifier;
});
