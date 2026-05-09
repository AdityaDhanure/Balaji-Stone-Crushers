import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/blast_repository.dart';

final blastRepositoryProvider = Provider<BlastRepository>((ref) {
  return BlastRepository();
});

class BlastState {
  final bool isLoading;
  final List<dynamic> blasts;
  final Map<String, dynamic>? activeBlast;
  final Map<String, dynamic>? selectedBlast;
  final int nextBlastNumber;
  final String? error;

  const BlastState({
    this.isLoading = false,
    this.blasts = const [],
    this.activeBlast,
    this.selectedBlast,
    this.nextBlastNumber = 1,
    this.error,
  });

  BlastState copyWith({
    bool? isLoading,
    List<dynamic>? blasts,
    Map<String, dynamic>? activeBlast,
    bool clearActiveBlast = false,
    Map<String, dynamic>? selectedBlast,
    int? nextBlastNumber,
    String? error,
  }) {
    return BlastState(
      isLoading: isLoading ?? this.isLoading,
      blasts: blasts ?? this.blasts,
      activeBlast: clearActiveBlast ? null : (activeBlast ?? this.activeBlast),
      selectedBlast: selectedBlast ?? this.selectedBlast,
      nextBlastNumber: nextBlastNumber ?? this.nextBlastNumber,
      error: error ?? this.error,
    );
  }
}

class BlastNotifier extends StateNotifier<BlastState> {
  final BlastRepository _repository;

  BlastNotifier(this._repository) : super(const BlastState());

  Future<void> loadBlasts() async {
    state = state.copyWith(isLoading: state.blasts.isEmpty, error: null);
    try {
      final blasts = await _repository.getAllBlasts();
      state = state.copyWith(isLoading: false, blasts: blasts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadActiveBlast() async {
    try {
      final activeBlast = await _repository.getActiveBlast();
      if (activeBlast == null) {
        state = state.copyWith(clearActiveBlast: true);
      } else {
        state = state.copyWith(activeBlast: activeBlast);
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadNextBlastNumber() async {
    try {
      final number = await _repository.getNextBlastNumber();
      state = state.copyWith(nextBlastNumber: number > 0 ? number : 1);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadBlastDetails(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final blast = await _repository.getBlastById(id);

      // 🔹 Show data immediately
      state = state.copyWith(
        selectedBlast: blast,
        isLoading: false,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createBlast(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createBlast(data);
      await loadBlasts();
      state = state.copyWith(
        selectedBlast: null,
      );
      await loadActiveBlast();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateBlast(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateBlast(id, data);
      await loadBlasts();
      state = state.copyWith(
        selectedBlast: null,
      );
      if (state.selectedBlast?['id']?.toString() == id.toString()) {
        await loadBlastDetails(id);
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

  Future<bool> deleteBlast(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteBlast(id);
      await loadBlasts();
      state = state.copyWith(
        selectedBlast: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> completeBlast(int id) async {
    // Immediately clear activeBlast → NoActiveBlastCard shows right away.
    state = state.copyWith(clearActiveBlast: true, isLoading: true, error: null);
    try {
      await _repository.completeBlast(id);
      await loadBlasts();

      // Keep activeBlast null — the blast is completed, no active blast exists.
      state = state.copyWith(isLoading: false);

      // Refresh detail screen if it is open.
      if (state.selectedBlast?['id']?.toString() == id.toString()) {
        await loadBlastDetails(id);
      }
      return true;
    } catch (e) {
      // Rollback: reload the real active blast from server.
      await loadActiveBlast();
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> reopenBlast(int id) async {
    // Optimistic update: find the blast in the already-loaded list and show it
    // as active immediately — state.activeBlast is null here (cleared on complete).
    final current = _blastById(id);
    if (current != null) {
      final optimistic = Map<String, dynamic>.from(current);
      optimistic['status'] = 'active';
      state = state.copyWith(activeBlast: optimistic);
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.reopenBlast(id);
      await loadBlasts();

      // Pull the now-active blast from the refreshed list for accurate values.
      final fromList = _blastById(id);
      if (fromList != null) {
        state = state.copyWith(activeBlast: fromList, isLoading: false);
      } else {
        await loadActiveBlast();
        state = state.copyWith(isLoading: false);
      }

      if (state.selectedBlast?['id']?.toString() == id.toString()) {
        await loadBlastDetails(id);
      }
      return true;
    } catch (e) {
      await loadActiveBlast();
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Returns the blast map from the in-memory [state.blasts] list for [id],
  /// or null if not present.
  Map<String, dynamic>? _blastById(int id) {
    final idStr = id.toString();
    for (final b in state.blasts) {
      if (b is Map<String, dynamic> && b['id']?.toString() == idStr) {
        return b;
      }
    }
    return null;
  }

  Future<List<String>> getVehicleTypes() async {
    final data = await _repository.getVehicleTypes();
    final types = data
        .map((t) => t['vehicle_type']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    return types;
  }

  Future<List<dynamic>> getVehiclesByType(String type) async {
    return await _repository.getVehiclesByType(type);
  }

  Future<bool> addTrip(Map<String, dynamic> data) async {
    try {
      await _repository.addTrip(data);
      if (state.selectedBlast != null) {
        await loadBlastDetails(state.selectedBlast!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateTrip(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateTrip(id, data);
      if (state.selectedBlast != null) {
        await loadBlastDetails(state.selectedBlast!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteTrip(int id) async {
    try {
      await _repository.deleteTrip(id);
      if (state.selectedBlast != null) {
        await loadBlastDetails(state.selectedBlast!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> addExpense(Map<String, dynamic> data) async {
    try {
      await _repository.addExpense(data);
      if (state.selectedBlast != null) {
        await loadBlastDetails(state.selectedBlast!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      if (state.selectedBlast != null) {
        await loadBlastDetails(state.selectedBlast!['id']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearSelectedBlast() {
    state = state.copyWith(selectedBlast: null);
  }

  Future<List<dynamic>> getTripsGroupedByDate(int blastId) async {
    try {
      return await _repository.getTripsGroupedByDate(blastId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  Future<List<dynamic>> getTripDates(int blastId) async {
    try {
      return await _repository.getTripDates(blastId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  Future<List<dynamic>> getExpensesGroupedByDate(int blastId) async {
    try {
      return await _repository.getExpensesGroupedByDate(blastId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  Future<List<dynamic>> getExpenseDates(int blastId) async {
    try {
      return await _repository.getExpenseDates(blastId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  Future<bool> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateExpense(id, data);
      if (state.selectedBlast != null) {
        await loadBlastDetails(state.selectedBlast!['id']);
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

final blastProvider = StateNotifierProvider<BlastNotifier, BlastState>((ref) {
  final notifier = BlastNotifier(ref.read(blastRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (previous, next) {
    notifier.loadBlasts();
    notifier.loadActiveBlast();
  });
  return notifier;
});
