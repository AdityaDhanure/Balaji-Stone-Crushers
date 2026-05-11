import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/widgets.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  String _filter = 'all';

  static const Map<String, String> _labels = {
    'all': 'All',
    'truck': 'Truck',
    'hyva': 'Hyva',
    'tractor': 'Tractor',
    'jcb': 'JCB',
    'loader': 'Loader',
    'pockland': 'Pockland',
    'roller': 'Roller',
    'paver': 'Paver',
    'water tanker': 'Water Tanker',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(vehicleProvider.notifier).loadExpiringDocuments();
    });
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    ref.listen(appRefreshProvider, (prev, next) {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(vehicleProvider.notifier).loadExpiringDocuments();
    }); 

    final vehicles = state.vehicles ?? [];

    final active = vehicles.where((v) {
      final status = v['status']?.toString().toLowerCase().trim();
      return status == 'active';
    }).length;

    final total = vehicles.length;

    final inactive = total - active < 0 ? 0 : total - active;

    final filtered = _filter == 'all'
        ? vehicles
        : vehicles.where((v) =>
            v['vehicle_type']?.toString().toLowerCase().trim() == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats header card
        Padding(
          padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, isSmall ? 12 : 20, isSmall ? 12 : 20, 0),
          child: _VehicleStatsCard(
                    total: total,
                    active: active,
                    expiring: (state.expiringDocuments ?? []).length,
                  )
        ),
        // Expiring alert
        if (state.expiringDocuments.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, 10, isSmall ? 12 : 20, 0),
            child: ExpiringDocumentsCard(
              expiringDocuments: state.expiringDocuments,
              onDocumentTap: (id) => context.push('/vehicles/detail/$id'),
            ),
          ),
        const SizedBox(height: 10),
        // Filter chips
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
          child: VehicleTypeFilterBar(
            selected: _filter,
            labels: _labels,
            vehicles: state.vehicles,
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        const SizedBox(height: 10),
        // List header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
          child: Row(children: [
            const Text('Vehicles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const Spacer(),
            if (state.isLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
            Text(' ${filtered.length} shown', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 8),
        // Vehicle list
        Expanded(
          child: filtered.isEmpty
              ? const VehicleEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, 0, isSmall ? 12 : 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VehicleListItem(vehicle: filtered[i], onTap: () => context.push('/vehicles/detail/${filtered[i]['id']}')),
                  ),
                ),
        ),
      ]),
      floatingActionButton: _VehicleFAB(onPressed: () => context.push('/vehicles/new')),
    );
  }
}

// ─── Stats Card ────────────────────────────────────────────────────────────────

class _VehicleStatsCard extends StatelessWidget {
  final int total;
  final int active;
  final int expiring;
  const _VehicleStatsCard({required this.total, required this.active, required this.expiring});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF1A2E4A), Color(0xFF1E4976), Color(0xFF0D3259)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF1E4976).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(top: -30, right: -20, child: _circle(120, 0.07)),
        Positioned(bottom: -40, right: 60, child: _circle(90, 0.05)),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Fleet Management', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$total vehicles registered', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _Chip(label: 'Total Fleet', value: '$total', icon: Icons.directions_car_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _Chip(label: 'Active', value: '$active', icon: Icons.check_circle_rounded, isGreen: true)),
              const SizedBox(width: 8),
              Expanded(child: _Chip(label: 'Inactive', value: '${(total - active) < 0 ? 0 : (total - active)}', icon: Icons.remove_circle_rounded)),
              if (expiring > 0) ...[
                const SizedBox(width: 8),
                Expanded(child: _Chip(label: 'Doc Expiring', value: '$expiring', icon: Icons.warning_rounded, isDanger: true)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)));
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGreen;
  final bool isDanger;
  const _Chip({required this.label, required this.value, required this.icon, this.isGreen = false, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    final accent = isGreen ? const Color(0xFF2ECC71) : isDanger ? const Color(0xFFE74C3C) : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: accent != null ? accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent != null ? accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: accent ?? Colors.white70, size: 14),
        const SizedBox(width: 5),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: accent ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
        ])),
      ]),
    );
  }
}

class _VehicleFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _VehicleFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16),
          child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(16),
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ])))),
    );
  }
}
