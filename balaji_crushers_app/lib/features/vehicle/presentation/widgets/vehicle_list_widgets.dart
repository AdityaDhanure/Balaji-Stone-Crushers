import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ─── Vehicle List Item ─────────────────────────────────────────────────────────

class VehicleListItem extends StatelessWidget {
  final dynamic vehicle;
  final VoidCallback onTap;

  const VehicleListItem({super.key, required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = vehicle['status'] == 'active';
    final icon = _vehicleIcon(vehicle['vehicle_type']?.toString() ?? '');
    final type = (vehicle['vehicle_type'] ?? '').toString();
    final trips = int.tryParse(vehicle['total_trips']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Gradient icon container
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [AppColors.primary.withValues(alpha: 0.18), AppColors.primary.withValues(alpha: 0.08)]
                      : [AppColors.border.withValues(alpha: 0.5), AppColors.border.withValues(alpha: 0.2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border),
              ),
              child: Icon(icon, color: isActive ? AppColors.primary : AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(vehicle['vehicle_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                _TypeChip(label: type.toUpperCase()),
              ]),
              const SizedBox(height: 4),
              Text('$trips trips · ${vehicle['owner_name'] ?? 'No owner'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _StatusDot(isActive: isActive),
              const SizedBox(height: 4),
              Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? AppColors.success : AppColors.textSecondary)),
            ]),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ]),
        ),
      ),
    );
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'truck': case 'hyva': return Icons.local_shipping_rounded;
      case 'tractor': return Icons.agriculture_rounded;
      case 'jcb': return Icons.construction_rounded;
      case 'loader': return Icons.precision_manufacturing_rounded;
      case 'pockland': return Icons.landscape_rounded;
      case 'roller': return Icons.tire_repair_rounded;
      case 'paver': return Icons.layers_rounded;
      case 'water tanker': return Icons.water_drop_rounded;
      default: return Icons.directions_car_rounded;
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
    child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.4)),
  );
}

class _StatusDot extends StatelessWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppColors.success : AppColors.textSecondary,
        boxShadow: isActive ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 4)] : null),
  );
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class VehicleEmptyState extends StatelessWidget {
  const VehicleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.35))),
      const SizedBox(height: 16),
      const Text('No vehicles found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      const Text('Add a vehicle using the button below', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]));
  }
}

// ─── Type Filter Chips ─────────────────────────────────────────────────────────

class VehicleTypeFilterBar extends StatelessWidget {
  final String selected;
  final Map<String, String> labels;
  final List<dynamic> vehicles;
  final Function(String) onChanged;

  const VehicleTypeFilterBar({super.key, required this.selected, required this.labels, required this.vehicles, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: labels.entries.map((e) {
          final count = e.key == 'all' ? vehicles.length : vehicles.where((v) => v['vehicle_type']?.toString().toLowerCase() == e.key).length;
          final isSelected = selected == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary)),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('$count', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary)),
                  ),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}