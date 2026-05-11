import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory UI state that should survive route switches while the app is open.
/// This provider is intentionally not persisted, so app restarts still use the
/// normal default screens.
final sessionTabIndexProvider =
    StateProvider.family<int, String>((ref, key) => 0);

final sessionSelectedIdProvider =
    StateProvider.family<int?, String>((ref, key) => null);
