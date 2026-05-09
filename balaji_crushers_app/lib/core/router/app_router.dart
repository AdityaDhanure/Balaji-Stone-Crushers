import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/blast/presentation/screens/blast_list_screen.dart';
import '../../features/blast/presentation/screens/blast_form_screen.dart';
import '../../features/blast/presentation/screens/blast_detail_screen.dart';
import '../../features/vehicle/presentation/screens/vehicle_list_screen.dart';
import '../../features/vehicle/presentation/screens/vehicle_form_screen.dart';
import '../../features/vehicle/presentation/screens/vehicle_detail_screen.dart';
import '../../features/diesel/presentation/screens/diesel_list_screen.dart';
import '../../features/product/presentation/screens/product_list_screen.dart';
import '../../features/customer/presentation/screens/customer_list_screen.dart';
import '../../features/billing/presentation/screens/billing_list_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_list_screen.dart';
import '../../features/employee/presentation/screens/employee_list_screen.dart';
import '../../features/attendance/presentation/screens/attendance_list_screen.dart';
import '../../features/salary/presentation/screens/salary_list_screen.dart';
import '../../features/expense/presentation/screens/expense_list_screen.dart';
import '../../features/report/presentation/screens/report_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../core/constants/app_strings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // ── Build the router ONCE — never recreate it on auth changes ─────────────
  // Recreating GoRouter tears down the entire widget tree, which disposes
  // in-flight loads and resets provider state. Instead we call refresh() when
  // isLoggedIn flips so the redirect callback re-evaluates cleanly.
  final router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Read fresh auth state on every redirect evaluation (not watch).
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            title: _getTitleFromRoute(state.matchedLocation),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/blast',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BlastListScreen(),
            ),
          ),
          GoRoute(
            path: '/blast/new',
            builder: (context, state) => const BlastFormScreen(),
          ),
          GoRoute(
            path: '/blast/detail/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return BlastDetailScreen(blastId: id);
            },
          ),
          GoRoute(
            path: '/blast/edit/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return BlastFormScreen(blastId: id);
            },
          ),
          GoRoute(
            path: '/vehicles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VehicleListScreen(),
            ),
          ),
          GoRoute(
            path: '/vehicles/new',
            builder: (context, state) => const VehicleFormScreen(),
          ),
          GoRoute(
            path: '/vehicles/detail/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return VehicleDetailScreen(vehicleId: id);
            },
          ),
          GoRoute(
            path: '/vehicles/edit/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return VehicleFormScreen(vehicleId: id);
            },
          ),
          GoRoute(
            path: '/diesel',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DieselListScreen(),
            ),
          ),
          GoRoute(
            path: '/crusher',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductListScreen(),
            ),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomerListScreen(),
            ),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BillingListScreen(),
            ),
          ),
          GoRoute(
            path: '/maintenance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MaintenanceListScreen(),
            ),
          ),
          GoRoute(
            path: '/employees',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EmployeeListScreen(),
            ),
          ),
          GoRoute(
            path: '/attendance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendanceListScreen(),
            ),
          ),
          GoRoute(
            path: '/salary',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SalaryListScreen(),
            ),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExpenseListScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportListScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  // Refresh redirect when login state flips — no GoRouter recreation needed.
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isLoggedIn != next.isLoggedIn) {
      router.refresh();
    }
  });

  return router;
});


String _getTitleFromRoute(String route) {
  switch (route) {
    case '/dashboard':
      return AppStrings.dashboard;
    case '/blast':
      return AppStrings.blast;
    case '/vehicles':
      return AppStrings.vehicles;
    case '/diesel':
      return AppStrings.diesel;
    case '/crusher':
      return AppStrings.crusher;
    case '/customers':
      return AppStrings.customers;
    case '/billing':
      return AppStrings.billing;
    case '/maintenance':
      return AppStrings.maintenance;
    case '/employees':
      return AppStrings.employees;
    case '/attendance':
      return AppStrings.attendance;
    case '/salary':
      return AppStrings.salary;
    case '/expenses':
      return AppStrings.expenses;
    case '/reports':
      return AppStrings.reports;
    case '/settings':
      return AppStrings.settings;
    case '/profile':
      return 'My Profile';
    default:
      return AppStrings.appName;
  }
}


