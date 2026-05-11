import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/ist_date_utils.dart';
import '../../providers/maintenance_provider.dart';
import '../common/maintenance_type_utils.dart';
import '../common/status_badge.dart';

class EquipmentDetailSheet extends ConsumerStatefulWidget {
  final Equipment equipment;
  final VoidCallback onUpdate;

  const EquipmentDetailSheet({
    super.key,
    required this.equipment,
    required this.onUpdate,
  });

  @override
  ConsumerState<EquipmentDetailSheet> createState() =>
      _EquipmentDetailSheetState();
}

class _EquipmentDetailSheetState
    extends ConsumerState<EquipmentDetailSheet> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  DateTime? _purchaseDate;
  DateTime? _warrantyDate;
  bool _isActive = true;
  String _selectedPhase = 'primary';
  String _selectedType = 'crusher';

  static const _phaseTypes = {
    'primary': ['crusher', 'screen', 'conveyor'],
    'secondary': ['crusher', 'screen', 'conveyor'],
    'tertiary': ['crusher', 'screen', 'conveyor'],
    'quaternary': ['crusher', 'screen', 'conveyor'],
    'generator': ['generator'],
  };

  List<String> get _availableTypes =>
      _phaseTypes[_selectedPhase] ?? ['crusher'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _descController =
        TextEditingController(text: widget.equipment.description ?? '');
    _selectedPhase = widget.equipment.equipmentPhase;
    _selectedType = widget.equipment.equipmentType;
    _isActive = widget.equipment.isActive;
    if (widget.equipment.purchaseDate != null) {
      _purchaseDate = appParseIstDate(widget.equipment.purchaseDate!);
    }
    if (widget.equipment.warrantyExpiry != null) {
      _warrantyDate = appParseIstDate(widget.equipment.warrantyExpiry!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final eq = widget.equipment;
    final icon = getEquipmentIcon(eq.equipmentType);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primaryLight.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eq.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${eq.code} • ${eq.phaseDisplay} • ${eq.typeDisplay}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (eq.isActive
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (eq.isActive
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        eq.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: eq.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      setState(() => _isEditing = !_isEditing),
                  icon: Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isEditing
                ? _buildEditForm(context)
                : _buildDetailView(context, fmt),
          ),
          if (_isEditing) _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, NumberFormat fmt) {
    final eq = widget.equipment;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total Spent',
                  value: '₹${fmt.format(eq.totalSpent)}',
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  label: 'Services',
                  value: '${eq.totalMaintenances}',
                  icon: Icons.build_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Details'),
          const SizedBox(height: 8),
          _DetailCard(rows: [
            if (eq.description != null && eq.description!.isNotEmpty)
              _Row(
                  icon: Icons.description_rounded,
                  label: 'Description',
                  value: eq.description!),
            if (eq.purchaseDate != null)
              _Row(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Purchased',
                  value: _fmtDate(eq.purchaseDate!)),
            if (eq.warrantyExpiry != null)
              _Row(
                  icon: Icons.shield_rounded,
                  label: 'Warranty',
                  value: _fmtDate(eq.warrantyExpiry!),
                  valueColor: eq.isWarrantyExpired ? AppColors.error : null),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Maintenance History'),
          const SizedBox(height: 8),
          _EquipmentHistory(equipmentId: eq.id),
          const SizedBox(height: 16),
          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await _showDeleteConfirm(context);
                if (confirmed == true && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  ref
                      .read(maintenanceProvider.notifier)
                      .deleteEquipment(widget.equipment.id);
                }
              },
              icon: const Icon(Icons.delete_rounded,
                  size: 16, color: AppColors.error),
              label: const Text('Delete Equipment',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Name *'),
          const SizedBox(height: 8),
          _field(
            controller: _nameController,
            hint: 'Equipment name',
            icon: Icons.precision_manufacturing_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _label('Phase'),
          const SizedBox(height: 8),
          _dropdown<String>(
            label: 'Phase',
            value: _selectedPhase,
            items: const [
              DropdownMenuItem(value: 'primary', child: Text('Primary')),
              DropdownMenuItem(
                  value: 'secondary', child: Text('Secondary')),
              DropdownMenuItem(value: 'tertiary', child: Text('Tertiary')),
              DropdownMenuItem(
                  value: 'quaternary', child: Text('Quaternary')),
              DropdownMenuItem(
                  value: 'generator', child: Text('Generator')),
            ],
            onChanged: (v) => setState(() {
              _selectedPhase = v ?? 'primary';
              _selectedType =
                  _phaseTypes[_selectedPhase]?.first ?? 'crusher';
            }),
          ),
          const SizedBox(height: 12),
          _label('Equipment Type'),
          const SizedBox(height: 8),
          _dropdown<String>(
            label: 'Type',
            value: _selectedType,
            items: _availableTypes
                .map((t) => DropdownMenuItem(
                    value: t, child: Text(_getTypeDisplay(t))))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedType = v ?? _availableTypes.first),
          ),
          const SizedBox(height: 12),
          _label('Description'),
          const SizedBox(height: 8),
          _field(
            controller: _descController,
            hint: 'Optional description…',
            icon: Icons.description_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
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
                          appTodayIstDate()
                              .add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _warrantyDate = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: const Text('Active', style: TextStyle(fontSize: 14)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
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
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5),
                  ),
          ),
        ),
      );

  Future<void> _onSave() async {
    setState(() => _isSaving = true);
    final ok = await ref.read(maintenanceProvider.notifier).updateEquipment(
      widget.equipment.id,
      {
        'name': _nameController.text,
        'equipment_type': _selectedType,
        'equipment_phase': _selectedPhase,
        'description': _descController.text.isEmpty
            ? null
            : _descController.text,
        'purchase_date': _purchaseDate == null ? null : appDateParam(_purchaseDate!),
        'warranty_expiry': _warrantyDate == null ? null : appDateParam(_warrantyDate!),
        'is_active': _isActive,
      },
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      widget.onUpdate();
      Navigator.pop(context);
    }
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Equipment'),
          content: Text(
              'Delete "${widget.equipment.name}"? This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  String _fmtDate(String raw) {
    try {
      final d = appParseIstDate(raw);
      if (d == null) return '—';
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  String _getTypeDisplay(String type) {
    switch (type) {
      case 'crusher': return 'Crusher';
      case 'screen': return 'Screen';
      case 'conveyor': return 'Conveyor';
      case 'generator': return 'Generator';
      case 'hopper': return 'Hopper';
      default: return type;
    }
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

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

// ─── Stats chip ───────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      );
}

// ─── Detail card ──────────────────────────────────────────────────────────────
class _Row {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
}

class _DetailCard extends StatelessWidget {
  final List<_Row> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final row = e.value;
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(row.icon,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: Text(row.label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: row.valueColor ?? AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                    color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Equipment history ────────────────────────────────────────────────────────
class _EquipmentHistory extends ConsumerStatefulWidget {
  final int equipmentId;
  const _EquipmentHistory({required this.equipmentId});

  @override
  ConsumerState<_EquipmentHistory> createState() => _EquipmentHistoryState();
}

class _EquipmentHistoryState extends ConsumerState<_EquipmentHistory> {
  List<MaintenanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await ref
        .read(maintenanceProvider.notifier)
        .loadEquipmentRecords(widget.equipmentId);
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('No maintenance history',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }
    return Column(
      children: _records.take(5).map((r) {
        final fmt = NumberFormat('#,##,###');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.build_rounded,
                    size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.maintenanceTypeDisplay,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(_fmtDate(r.maintenanceDate),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${fmt.format(r.cost)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary)),
                  MaintenanceStatusBadge(status: r.status, compact: true),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _fmtDate(String raw) {
    try {
      final d = appParseIstDate(raw);
      if (d == null) return '—';
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ─── Date tile ────────────────────────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.date, required this.onTap});

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
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
