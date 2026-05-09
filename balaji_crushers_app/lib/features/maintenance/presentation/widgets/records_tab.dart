import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/maintenance_provider.dart';
import 'maintenance_record_card.dart';
import 'common/empty_state.dart';

class RecordsTab extends ConsumerStatefulWidget {
  final bool isSmallScreen;
  final void Function(MaintenanceRecord) onRecordTap;
  final void Function(MaintenanceRecord) onEditRecord;
  final void Function(int, String) onDeleteRecord;

  const RecordsTab({
    super.key,
    this.isSmallScreen = false,
    required this.onRecordTap,
    required this.onEditRecord,
    required this.onDeleteRecord,
  });

  @override
  ConsumerState<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends ConsumerState<RecordsTab> {
  String _selectedType = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceProvider);

    final filtered = state.records.where((r) {
      final typeMatch = switch (_selectedType) {
        'equipment' => (r.equipmentId ?? 0) > 0 && (r.vehicleId ?? 0) == 0,
        'vehicle'   => (r.vehicleId ?? 0) > 0,
        _           => true,
      };
      if (!typeMatch) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.typeDisplay.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.maintenanceTypeDisplay.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        // Search bar
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search records…',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textSecondary),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filter chips
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                  label: 'All',
                  value: 'all',
                  selected: _selectedType == 'all',
                  onSelected: (v) => setState(() => _selectedType = v)),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Equipment',
                  value: 'equipment',
                  selected: _selectedType == 'equipment',
                  onSelected: (v) => setState(() => _selectedType = v)),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Vehicles',
                  value: 'vehicle',
                  selected: _selectedType == 'vehicle',
                  onSelected: (v) => setState(() => _selectedType = v)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // List
        Expanded(
          child: state.isLoading && filtered.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? MaintenanceEmptyState(
                      message: 'No maintenance records',
                      subtitle: _selectedType != 'all'
                          ? 'Try changing the filter'
                          : 'Add your first maintenance record',
                      icon: Icons.build_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final record = filtered[i];
                        return MaintenanceRecordCard(
                          record: record,
                          onTap: () => widget.onRecordTap(record),
                          onEdit: () => widget.onEditRecord(record),
                          onDelete: () => widget.onDeleteRecord(
                              record.id, record.maintenanceTypeDisplay),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(selected ? 'all' : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}