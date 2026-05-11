import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_refresh_provider.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/blast/presentation/providers/blast_provider.dart';
import '../../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../../features/diesel/presentation/providers/diesel_provider.dart';
import '../../features/product/presentation/providers/product_provider.dart';
import '../../features/customer/presentation/providers/customer_provider.dart';
import '../../features/billing/presentation/providers/billing_provider.dart';
import '../../features/maintenance/presentation/providers/maintenance_provider.dart';
import '../../features/employee/presentation/providers/employee_provider.dart';
import '../../features/expense/presentation/providers/expense_provider.dart';
import '../../features/report/presentation/providers/report_provider.dart';
import 'sidebar.dart';
import 'top_bar.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final String title;

  const AppShell({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    ref.listen<AsyncValue<int>>(apiMutationProvider, (previous, next) {
      final previousValue = previous?.valueOrNull;
      final nextValue = next.valueOrNull;
      if (nextValue != null && nextValue != previousValue) {
        ref.read(appRefreshProvider.notifier).refresh();
      }
    });

    // ── Track previous route ─────────────────────────────────────────────────
    // Skip /profile and /settings — these are "secondary" screens.
    if (currentRoute != '/profile' && currentRoute != '/settings') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(previousRouteProvider) != currentRoute) {
          ref.read(previousRouteProvider.notifier).state = currentRoute;
        }
      });
    }

    // ── Global Refresh Listener ──────────────────────────────────────────────
    // When the TopBar refresh button is pressed, appRefreshProvider increments.
    // We reload all StateNotifier-based providers here, and invalidate
    // FutureProvider.family providers so they re-fetch on next watch.
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous == null || previous == next) return;

      // StateNotifier providers — call their load methods
      ref.read(dashboardProvider.notifier).loadAll();
      ref.read(blastProvider.notifier).loadBlasts();
      ref.read(blastProvider.notifier).loadActiveBlast();
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(vehicleProvider.notifier).loadExpiringDocuments();
      ref.read(dieselProvider.notifier).loadAllData();
      ref.read(productProvider.notifier).loadAllData();
      ref.read(customerProvider.notifier).loadAllData();
      ref.read(billingProvider.notifier).loadAllData();
      ref.read(maintenanceProvider.notifier).loadAllData();
      ref.read(employeeProvider.notifier).loadAllData();

      // FutureProvider.family providers — invalidate so they re-fetch on watch
      ref.invalidate(unifiedExpensesProvider);
      ref.invalidate(expenseSummaryProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(overviewSummaryProvider);
      ref.invalidate(salesReportProvider);
      ref.invalidate(expenseSummaryReportProvider);
      ref.invalidate(profitLossProvider);
      ref.invalidate(yearlyTrendProvider);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                TopBar(title: title),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
