import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/vehicle_form_widgets.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final int? vehicleId;
  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _rtoEmiCtrl = TextEditingController(text: '0');
  final _odometerCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  String _vehicleType = 'truck';
  DateTime? _insuranceExpiry;
  DateTime? _pucExpiry;
  DateTime? _passingExpiry;
  DateTime? _roadTaxExpiry;
  DateTime? _rtoEmiDueDate;
  bool _isLoading = false;
  bool _populated = false;

  final _vehicleTypes = ['Truck', 'Hyva', 'Pockland', 'Tractor', 'JCB', 'Loader', 'Roller', 'Paver', 'Water Tanker'];
  final _dateFormat = DateFormat('dd MMM yyyy');

  bool get _isEdit => widget.vehicleId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      Future.microtask(() => ref.read(vehicleProvider.notifier).loadVehicleDetails(widget.vehicleId!));
    }
  }

  @override
  void dispose() {
    _vehicleNumberCtrl.dispose();
    _ownerCtrl.dispose();
    _rtoEmiCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _populate(dynamic v) {
    if (_populated) return;
    _populated = true;
    _vehicleNumberCtrl.text = v['vehicle_number'] ?? '';
    _ownerCtrl.text = v['owner_name'] ?? '';
    _rtoEmiCtrl.text = v['rto_emi_amount']?.toString() ?? '0';
    _odometerCtrl.text = v['odometer_reading']?.toString() ?? '0';
    _notesCtrl.text = v['notes'] ?? '';
    _vehicleType = (v['vehicle_type']?.toString().toLowerCase() ?? 'truck');
    setState(() {
      if (v['insurance_expiry'] != null) _insuranceExpiry = appParseIstDate(v['insurance_expiry']);
      if (v['puc_expiry'] != null) _pucExpiry = appParseIstDate(v['puc_expiry']);
      if (v['passing_expiry'] != null) _passingExpiry = appParseIstDate(v['passing_expiry']);
      if (v['road_tax_expiry'] != null) _roadTaxExpiry = appParseIstDate(v['road_tax_expiry']);
      if (v['rto_emi_due_date'] != null) _rtoEmiDueDate = appParseIstDate(v['rto_emi_due_date']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (_isEdit && state.selectedVehicle != null && !_populated) {
      _populate(state.selectedVehicle!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Premium AppBar ──────────────────────────────────────────────────
        _FormAppBar(isEdit: _isEdit, onBack: () => context.pop()),
        // ── Form Body ───────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(isSmall ? 14 : 24, 16, isSmall ? 14 : 24, 40),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Section 1 — Basic Info
                VehicleFormCard(
                  title: 'Basic Information',
                  icon: Icons.directions_car_rounded,
                  children: [
                    VehicleFormTextField(
                      controller: _vehicleNumberCtrl,
                      label: 'Vehicle Number *',
                      hint: 'e.g. RJ14CA1234',
                      prefixIcon: Icons.badge_rounded,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v == null || v.isEmpty) ? 'Vehicle number is required' : null,
                    ),
                    const SizedBox(height: 12),
                    VehicleTypeDropdown(
                      value: _vehicleType,
                      vehicleTypes: _vehicleTypes,
                      onChanged: (v) => setState(() => _vehicleType = v ?? 'truck'),
                    ),
                    const SizedBox(height: 12),
                    VehicleFormTextField(
                      controller: _ownerCtrl,
                      label: 'Owner Name',
                      hint: 'Full owner name',
                      prefixIcon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    VehicleFormTextField(
                      controller: _odometerCtrl,
                      label: 'Odometer Reading',
                      hint: '0',
                      suffix: ' km',
                      prefixIcon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 2 — Document Expiry
                VehicleFormCard(
                  title: 'Document Expiry Dates',
                  icon: Icons.description_rounded,
                  children: [
                    const DocumentExpiryInfo(),
                    const SizedBox(height: 12),
                    _dateGrid(isSmall),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 3 — RTO EMI
                VehicleFormCard(
                  title: 'RTO EMI Details',
                  icon: Icons.account_balance_wallet_rounded,
                  children: [
                    Row(children: [
                      Expanded(child: VehicleFormTextField(
                        controller: _rtoEmiCtrl,
                        label: 'EMI Amount',
                        prefix: '₹ ',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: DatePickerField(
                        label: 'EMI Due Date',
                        value: _rtoEmiDueDate,
                        dateFormat: _dateFormat,
                        onChanged: (d) => setState(() => _rtoEmiDueDate = d),
                      )),
                    ]),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 4 — Notes
                VehicleFormCard(
                  title: 'Additional Notes',
                  icon: Icons.notes_rounded,
                  children: [
                    VehicleFormTextField(
                      controller: _notesCtrl,
                      label: 'Notes',
                      hint: 'Any additional information...',
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SubmitButton(
                  isLoading: _isLoading,
                  text: _isEdit ? 'Update Vehicle' : 'Add Vehicle',
                  onPressed: _submit,
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dateGrid(bool isSmall) {
    final fields = [
      ('Insurance', _insuranceExpiry, (DateTime? d) => setState(() => _insuranceExpiry = d), Icons.security_rounded),
      ('PUC', _pucExpiry, (DateTime? d) => setState(() => _pucExpiry = d), Icons.eco_rounded),
      ('Passing', _passingExpiry, (DateTime? d) => setState(() => _passingExpiry = d), Icons.verified_rounded),
      ('Road Tax', _roadTaxExpiry, (DateTime? d) => setState(() => _roadTaxExpiry = d), Icons.receipt_long_rounded),
    ];

    if (isSmall) {
      return Column(
        children: fields.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DatePickerField(label: f.$1, value: f.$2, dateFormat: _dateFormat, onChanged: f.$3),
        )).toList(),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: fields.map((f) => SizedBox(
      width: (MediaQuery.of(context).size.width - 48 - 32 - 10) / 2,
      child: DatePickerField(label: f.$1, value: f.$2, dateFormat: _dateFormat, onChanged: f.$3),
    )).toList());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'vehicle_number': _vehicleNumberCtrl.text.trim().toUpperCase(),
      'vehicle_type': _vehicleType,
      'owner_name': _ownerCtrl.text.trim(),
      'insurance_expiry': _insuranceExpiry == null ? null : appDateParam(_insuranceExpiry!),
      'puc_expiry': _pucExpiry == null ? null : appDateParam(_pucExpiry!),
      'passing_expiry': _passingExpiry == null ? null : appDateParam(_passingExpiry!),
      'road_tax_expiry': _roadTaxExpiry == null ? null : appDateParam(_roadTaxExpiry!),
      'rto_emi_amount': double.tryParse(_rtoEmiCtrl.text) ?? 0,
      'rto_emi_due_date': _rtoEmiDueDate == null ? null : appDateParam(_rtoEmiDueDate!),
      'odometer_reading': double.tryParse(_odometerCtrl.text) ?? 0,
      'notes': _notesCtrl.text.trim(),
    };

    final success = _isEdit
        ? await ref.read(vehicleProvider.notifier).updateVehicle(widget.vehicleId!, data)
        : await ref.read(vehicleProvider.notifier).createVehicle(data);

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Vehicle updated successfully!' : 'Vehicle added successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }
}

// ─── Premium Form AppBar ───────────────────────────────────────────────────────

class _FormAppBar extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onBack;
  const _FormAppBar({required this.isEdit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A2E4A), Color(0xFF1E4976)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
          child: Row(children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(isEdit ? 'Update vehicle information' : 'Register a new vehicle', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}
