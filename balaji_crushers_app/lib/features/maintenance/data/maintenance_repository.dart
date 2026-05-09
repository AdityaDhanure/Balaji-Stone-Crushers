import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class MaintenanceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getMaintenanceRecords({String? type, String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (type != null) params['type'] = type;
      if (status != null) params['status'] = status;
      final response = await _apiClient.dio.get('/maintenance', queryParameters: params);
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get maintenance records',
      );
    }
  }

  Future<List<dynamic>> getRecordsByEquipment(int equipmentId) async {
    try {
      final response = await _apiClient.dio
          .get('/maintenance/equipment/$equipmentId/records');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get records by equipment',
      );
    }
  }

  Future<dynamic> getMaintenanceById(int id) async {
    try {
      final response = await _apiClient.dio.get('/maintenance/$id');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get maintenance by ID',
      );
    }
  }

  Future<dynamic> createMaintenance(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/maintenance', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to create maintenance',
      );
    }
  }

  Future<dynamic> updateMaintenance(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/maintenance/$id', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to update maintenance',
      );
    }
  }

  Future<void> deleteMaintenance(int id) async {
    try {
      final response = await _apiClient.dio.delete('/maintenance/$id');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to delete maintenance',
      );
    }
  }

  Future<void> deleteMaintenanceWithRecovery(int id, bool recoverParts) async {
    try {
      final response = await _apiClient.dio.delete(
        '/maintenance/$id',
        queryParameters: {'recover_parts': recoverParts.toString()},
      );
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to delete maintenance with recovery',
      );
    }
  }

  Future<List<dynamic>> getRecordParts(int recordId) async {
    try {
      final response = await _apiClient.dio.get('/maintenance/record-parts/$recordId');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get record parts',
      );
    }
  }

  Future<dynamic> getMaintenanceStats() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/stats');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get maintenance stats',
      );
    }
  }

  Future<List<dynamic>> getDueSoon({int days = 7}) async {
    try {
      final response = await _apiClient.dio.get('/maintenance/due-soon', queryParameters: {'days': days});
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get due soon maintenance',
      );
    }
  }

  Future<List<dynamic>> getEquipment() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/equipment');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get equipment',
      );
    }
  }

  Future<List<dynamic>> getActiveEquipment() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/equipment/active');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get active equipment',
      );
    }
  }

  Future<dynamic> createEquipment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/maintenance/equipment', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to create equipment',
      );
    }
  }

  Future<void> deleteEquipment(int id) async {
    try {
      final response = await _apiClient.dio.delete('/maintenance/equipment/$id');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to delete equipment',
      );
    }
  }

  Future<String> getNextEquipmentCode(String type) async {
    try {
      final response = await _apiClient.dio.get('/maintenance/equipment/next-code', queryParameters: {'type': type});
      final data = _unwrap(response.data);
      return data['code']?.toString() ?? '';
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get next code',
      );
    }
  }

  Future<List<dynamic>> getSchedules() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/schedules');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get schedules',
      );
    }
  }

  Future<void> markScheduleComplete(int id) async {
    try {
      final response = await _apiClient.dio.patch('/maintenance/schedules/$id/complete');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to mark complete',
      );
    }
  }

  // Vendor methods
  Future<List<dynamic>> getVendors() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/vendors');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get vendors',
      );
    }
  }

  Future<dynamic> createVendor(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/maintenance/vendors', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to create vendor',
      );
    }
  }

  Future<void> deleteVendor(int id) async {
    try {
      final response = await _apiClient.dio.delete('/maintenance/vendors/$id');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to delete vendor',
      );
    }
  }

  // Spare Parts methods
  Future<List<dynamic>> getParts() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/parts');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get parts',
      );
    }
  }

  Future<dynamic> createPart(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/maintenance/parts', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to create part',
      );
    }
  }

  Future<void> deletePart(int id) async {
    try {
      final response = await _apiClient.dio.delete('/maintenance/parts/$id');
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to delete part',
      );
    }
  }

  Future<dynamic> updateEquipment(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/maintenance/equipment/$id', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to update equipment',
      );
    }
  }

  Future<dynamic> updateVendor(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/maintenance/vendors/$id', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to update vendor',
      );
    }
  }

  Future<dynamic> updatePart(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/maintenance/parts/$id', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to update part',
      );
    }
  }

  Future<String> getNextPartNumber() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/parts/next-part-number');
      final data = _unwrap(response.data);
      return data['part_number']?.toString() ?? '';
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get next part number',
      );
    }
  }

  Future<List<dynamic>> getPredefinedParts() async {
    try {
      final response = await _apiClient.dio.get('/maintenance/parts/predefined');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? e.response?.data['error']
            : e.message ?? 'Failed to get predefined parts',
      );
    }
  }
}
