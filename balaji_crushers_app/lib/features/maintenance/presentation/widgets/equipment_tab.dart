import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/maintenance_provider.dart';
import 'equipment_card.dart';
import 'common/empty_state.dart';

class EquipmentTab extends ConsumerWidget {
  final bool isSmallScreen;
  final void Function(Equipment) onEquipmentTap;
  final void Function(Equipment) onEditEquipment;
  final void Function(int, String) onDeleteEquipment;

  const EquipmentTab({
    super.key,
    this.isSmallScreen = false,
    required this.onEquipmentTap,
    required this.onEditEquipment,
    required this.onDeleteEquipment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceProvider);

    if (state.isLoading && state.equipment.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.equipment.isEmpty) {
      return const MaintenanceEmptyState(
        message: 'No equipment added',
        subtitle: 'Add crushers, screens, conveyors and more',
        icon: Icons.precision_manufacturing_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: state.equipment.length,
      itemBuilder: (_, i) {
        final eq = state.equipment[i];
        return EquipmentCard(
          equipment: eq,
          onTap: () => onEquipmentTap(eq),
          onEdit: () => onEditEquipment(eq),
          onDelete: () => onDeleteEquipment(eq.id, eq.name),
        );
      },
    );
  }
}