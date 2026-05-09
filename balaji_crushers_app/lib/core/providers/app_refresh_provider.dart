import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRefreshNotifier extends StateNotifier<int> {
  AppRefreshNotifier() : super(0);

  void refresh() {
    state++;
  }
}

final appRefreshProvider = StateNotifierProvider<AppRefreshNotifier, int>((ref) {
  return AppRefreshNotifier();
});

/// Stores the last non-profile route so the Profile back button
/// knows which screen to return to.
final previousRouteProvider = StateProvider<String>((ref) => '/dashboard');
