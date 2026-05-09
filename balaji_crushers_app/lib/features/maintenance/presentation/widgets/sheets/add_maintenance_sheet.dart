import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/ist_date_utils.dart';
import '../../providers/maintenance_provider.dart';
import '../../../../vehicle/presentation/providers/vehicle_provider.dart';

class AddMaintenanceSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final MaintenanceRecord? existingRecord;

  const AddMaintenanceSheet({
    super.key,
    required this.onSave,
    this.existingRecord,
  });

  @override
  ConsumerState<AddMaintenanceSheet> createState() =>
      _AddMaintenanceSheetState();
}

class _AddMaintenanceSheetState extends ConsumerState<AddMaintenanceSheet> {
  String _maintenanceFor = 'equipment';
  int? _selectedEquipmentId;
  int? _selectedVehicleId;
  String? _selectedVehicleType;
  String _maintenanceType = 'service';
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  int? _selectedVendorId;
  String _selectedVendorName = '';
  final _partsUsedController = TextEditingController();
  DateTime _maintenanceDate = appTodayIstDate();
  DateTime? _nextDueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    if (record != null) {
      _maintenanceType = record.maintenanceType;
      _descriptionController.text = record.description;
      _costController.text = record.cost.toString();
      _selectedVendorName = record.vendorName ?? '';
      _maintenanceDate = appParseIstDate(record.maintenanceDate) ?? _maintenanceDate;
      if (record.nextDueDate != null) {
        _nextDueDate = appParseIstDate(record.nextDueDate!);
      }
      if (record.equipmentId != null) {
        _maintenanceFor = 'equipment';
        _selectedEquipmentId = record.equipmentId;
      } else if (record.vehicleId != null) {
        _maintenanceFor = 'vehicle';
        _selectedVehicleId = record.vehicleId;
        _selectedVehicleType = record.vehicleType;
      }
    }
    Future.microtask(() {
      ref.read(maintenanceProvider.notifier).loadEquipment();
      ref.read(maintenanceProvider.notifier).loadVendors();
      ref.read(vehicleProvider.notifier).loadVehicles();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _partsUsedController.dispose();
    super.dispose();
  }

  List<String> get _availableVehicleTypes {
    final vehicles = ref.read(vehicleProvider).vehicles;
    final types = <String>[];
    for (final v in vehicles) {
      final t = (v as Map<String, dynamic>)['vehicle_type']?.toString();
      if (t != null && t.isNotEmpty && !types.contains(t)) types.add(t);
    }
    return types;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final isEdit = widget.existingRecord != null;

    final filteredVehicles = _selectedVehicleType == null
        ? <Map<String, dynamic>>[]
        : vehicleState.vehicles
            .where((v) =>
                (v as Map<String, dynamic>)['vehicle_type'] ==
                _selectedVehicleType)
            .cast<Map<String, dynamic>>()
            .toList();

    final canSave = (_maintenanceFor == 'equipment'
            ? _selectedEquipmentId != null
            : _selectedVehicleId != null) &&
        _descriptionController.text.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Maintenance Record' : 'Add Maintenance Record',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Maintenance For'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _ToggleChip(
                        label: 'Equipment',
                        icon: Icons.precision_manufacturing_rounded,
                        selected: _maintenanceFor == 'equipment',
                        onTap: () =>
                            setState(() => _maintenanceFor = 'equipment'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _ToggleChip(
                        label: 'Vehicle',
                        icon: Icons.local_shipping_rounded,
                        selected: _maintenanceFor == 'vehicle',
                        onTap: () =>
                            setState(() => _maintenanceFor = 'vehicle'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_maintenanceFor == 'equipment')
                    _styledDropdown<int>(
                      label: 'Select Equipment *',
                      value: _selectedEquipmentId,
                      icon: Icons.precision_manufacturing_rounded,
                      items: state.equipment
                          .map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text('${e.name} (${e.code})'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedEquipmentId = v),
                    )
                  else
                    Column(
                      children: [
                        _styledDropdown<String>(
                          label: 'Vehicle Type *',
                          value: _selectedVehicleType,
                          icon: Icons.category_rounded,
                          items: _availableVehicleTypes
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedVehicleType = v;
                            _selectedVehicleId = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        _styledDropdown<int>(
                          label: 'Select Vehicle *',
                          value: _selectedVehicleId,
                          icon: Icons.local_shipping_rounded,
                          items: filteredVehicles.map((v) {
                            final num = v['vehicle_number']?.toString() ??
                                v['number_plate']?.toString() ??
                                'Unknown';
                            final type = v['vehicle_type']?.toString() ?? '';
                            return DropdownMenuItem(
                                value: v['id'] as int,
                                child: Text('$type — $num'));
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedVehicleId = v),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _sectionLabel('Maintenance Type'),
                  const SizedBox(height: 8),
                  _styledDropdown<String>(
                    label: 'Type',
                    value: _maintenanceType,
                    icon: Icons.category_rounded,
                    items: const [
                      DropdownMenuItem(
                          value: 'service', child: Text('Service')),
                      DropdownMenuItem(
                          value: 'repair', child: Text('Repair')),
                      DropdownMenuItem(
                          value: 'inspection', child: Text('Inspection')),
                      DropdownMenuItem(
                          value: 'oil_change', child: Text('Oil Change')),
                      DropdownMenuItem(
                          value: 'replacement',
                          child: Text('Part Replacement')),
                    ],
                    onChanged: (v) =>
                        setState(() => _maintenanceType = v!),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Description *'),
                  const SizedBox(height: 8),
                  _styledTextField(
                    controller: _descriptionController,
                    hint: 'Describe the work done…',
                    icon: Icons.description_rounded,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Date & Cost'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Date',
                          date: _maintenanceDate,
                          onTap: () async {
                            final p = await showDatePicker(
                              context: context,
                              initialDate: _maintenanceDate,
                              firstDate: DateTime(2020),
                              lastDate: appTodayIstDate()
                                  .add(const Duration(days: 365)),
                            );
                            if (p != null) {
                              setState(() => _maintenanceDate = p);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _styledTextField(
                          controller: _costController,
                          hint: 'Cost (₹)',
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: 'Next Due Date (optional)',
                    date: _nextDueDate,
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _nextDueDate ??
                            appTodayIstDate().add(const Duration(days: 30)),
                        firstDate: appTodayIstDate(),
                        lastDate: appTodayIstDate()
                            .add(const Duration(days: 365 * 2)),
                      );
                      if (p != null) setState(() => _nextDueDate = p);
                    },
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Vendor (optional)'),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (_, ref, __) {
                      final vendors = ref.watch(maintenanceProvider).vendors;
                      return _styledDropdown<int>(
                        label: 'Select Vendor',
                        value: _selectedVendorId,
                        icon: Icons.business_rounded,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('None')),
                          ...vendors.map((v) => DropdownMenuItem(
                              value: v.id, child: Text(v.name))),
                        ],
                        onChanged: (v) => setState(() {
                          _selectedVendorId = v;
                          _selectedVendorName = v == null
                              ? ''
                              : vendors
                                  .firstWhere((vn) => vn.id == v)
                                  .name;
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Parts Used (optional)'),
                  const SizedBox(height: 8),
                  _styledTextField(
                    controller: _partsUsedController,
                    hint: 'e.g. Oil filter, brake pads…',
                    icon: Icons.settings_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSave && !_isSaving ? _onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        isEdit ? 'SAVE CHANGES' : 'SAVE RECORD',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() => _isSaving = true);
    await widget.onSave({
      'equipment_id':
          _maintenanceFor == 'equipment' ? _selectedEquipmentId : null,
      'vehicle_id':
          _maintenanceFor == 'vehicle' ? _selectedVehicleId : null,
      'maintenance_type': _maintenanceType,
      'description': _descriptionController.text,
      'maintenance_date':
          appDateParam(_maintenanceDate),
      'next_due_date': _nextDueDate != null
          ? appDateParam(_nextDueDate!)
          : null,
      'cost': double.tryParse(_costController.text) ?? 0,
      'vendor_name':
          _selectedVendorName.isEmpty ? null : _selectedVendorName,
      'vendor_id': _selectedVendorId,
      'status': 'completed',
    });
    if (mounted) setState(() => _isSaving = false);
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(icon,
                size: 18, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      );

  Widget _styledDropdown<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      date == null
                          ? 'Tap to select'
                          : DateFormat('dd MMM yyyy').format(date!),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
