import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/ist_date_utils.dart';
import '../../providers/maintenance_provider.dart';

class AddEquipmentSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddEquipmentSheet({super.key, required this.onSave});

  @override
  ConsumerState<AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends ConsumerState<AddEquipmentSheet> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPhase = 'primary';
  String _selectedType = 'crusher';
  DateTime? _purchaseDate;
  DateTime? _warrantyDate;
  bool _isActive = true;
  bool _isSaving = false;

  static const _phaseTypes = {
    'primary': ['crusher', 'screen', 'conveyor'],
    'secondary': ['crusher', 'screen', 'conveyor'],
    'tertiary': ['crusher', 'screen', 'conveyor'],
    'quaternary': ['crusher', 'screen', 'conveyor'],
    'generator': ['generator'],
  };

  List<String> get _availableTypes => _phaseTypes[_selectedPhase] ?? ['crusher'];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _typeDisplayName(String type) {
    switch (type) {
      case 'crusher': return 'Crusher';
      case 'screen': return 'Screen';
      case 'conveyor': return 'Conveyor';
      case 'generator': return 'Generator';
      default: return type;
    }
  }

  Future<void> _refreshCode() async {
    final code = await ref
        .read(maintenanceProvider.notifier)
        .getNextEquipmentCode('${_selectedPhase}_$_selectedType');
    if (mounted) _codeController.text = code;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Equipment',
                  style: TextStyle(
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Equipment Name *'),
                  const SizedBox(height: 8),
                  _field(
                    controller: _nameController,
                    hint: 'e.g. Primary Crusher C1',
                    icon: Icons.precision_manufacturing_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _label('Phase'),
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    label: 'Select Phase',
                    value: _selectedPhase,
                    icon: Icons.layers_rounded,
                    items: const [
                      DropdownMenuItem(value: 'primary', child: Text('Primary')),
                      DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
                      DropdownMenuItem(value: 'tertiary', child: Text('Tertiary')),
                      DropdownMenuItem(value: 'quaternary', child: Text('Quaternary')),
                      DropdownMenuItem(value: 'generator', child: Text('Generator')),
                    ],
                    onChanged: (v) async {
                      setState(() {
                        _selectedPhase = v ?? 'primary';
                        _selectedType = _phaseTypes[_selectedPhase]?.first ?? 'crusher';
                      });
                      await _refreshCode();
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('Equipment Type'),
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    label: 'Select Type',
                    value: _selectedType,
                    icon: Icons.category_rounded,
                    items: _availableTypes
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(_typeDisplayName(t))))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _selectedType = v ?? _availableTypes.first);
                      await _refreshCode();
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('Auto Code'),
                  const SizedBox(height: 8),
                  _field(
                    controller: _codeController,
                    hint: 'Auto-generated',
                    icon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 16),
                  _label('Description'),
                  const SizedBox(height: 8),
                  _field(
                    controller: _descController,
                    hint: 'Optional description…',
                    icon: Icons.description_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _label('Dates'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: 'Purchase Date',
                          date: _purchaseDate,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate ?? appTodayIstDate(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => _purchaseDate = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          label: 'Warranty Expiry',
                          date: _warrantyDate,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _warrantyDate ??
                                  appTodayIstDate().add(const Duration(days: 365)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => _warrantyDate = d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      title: const Text('Active',
                          style: TextStyle(fontSize: 14)),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nameController.text.isEmpty || _isSaving
                    ? null
                    : _onSave,
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'ADD EQUIPMENT',
                        style: TextStyle(
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
      'name': _nameController.text,
      'code': _codeController.text,
      'equipment_type': _selectedType,
      'equipment_phase': _selectedPhase,
      'description': _descController.text.isEmpty ? null : _descController.text,
      'purchase_date': _purchaseDate == null ? null : appDateParam(_purchaseDate!),
      'warranty_expiry': _warrantyDate == null ? null : appDateParam(_warrantyDate!),
      'is_active': _isActive,
    });
    if (mounted) setState(() => _isSaving = false);
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  Widget _dropdown<T>({
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

// ─── date tile ────────────────────────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                    Text(
                      date == null
                          ? 'Select'
                          : DateFormat('dd MMM yyyy').format(date!),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
