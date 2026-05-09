import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/blast_provider.dart';
import '../widgets/blast_form_widgets.dart';

const _kAccent = Color(0xFFE67E22);
const _kAccentDark = Color(0xFFD35400);

class BlastFormScreen extends ConsumerStatefulWidget {
  final int? blastId;
  const BlastFormScreen({super.key, this.blastId});

  @override
  ConsumerState<BlastFormScreen> createState() => _BlastFormScreenState();
}

class _BlastFormScreenState extends ConsumerState<BlastFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feetCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '190');
  final _notesCtrl = TextEditingController();

  String _blastType = 'bore';
  DateTime _blastDate = appTodayIstDate();
  bool _isLoading = false;
  bool _populated = false;
  final _dateFormat = DateFormat('dd MMM yyyy');

  bool get _isEdit => widget.blastId != null;

  double get _feet => double.tryParse(_feetCtrl.text) ?? 0;
  double get _rate => double.tryParse(_rateCtrl.text) ?? 0;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      Future.microtask(() => ref.read(blastProvider.notifier).loadBlastDetails(widget.blastId!));
    } else {
      Future.microtask(() => ref.read(blastProvider.notifier).loadNextBlastNumber());
    }
    _feetCtrl.addListener(() => setState(() {}));
    _rateCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _feetCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _populate(dynamic b) {
    if (_populated) return;
    _populated = true;
    setState(() {
      _blastType = b['blast_type'] ?? 'bore';
      _blastDate = appParseIstDate(b['blast_date']) ?? _blastDate;
      _feetCtrl.text = b['feet']?.toString() ?? '';
      _rateCtrl.text = b['rate']?.toString() ?? '190';
      _notesCtrl.text = b['notes'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blastProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (_isEdit && state.selectedBlast != null && !_populated) _populate(state.selectedBlast!);

    final blastNumber = _isEdit
        ? (state.selectedBlast?['blast_number']?.toString() ?? '—')
        : state.nextBlastNumber.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Gradient AppBar ─────────────────────────────────────────────────
        _BlastFormAppBar(isEdit: _isEdit, onBack: () => context.pop()),
        // ── Form ────────────────────────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(isSmall ? 14 : 24, 16, isSmall ? 14 : 24, 40),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Section 1 — Blast Details
              BlastFormCard(
                title: 'Blast Details',
                icon: Icons.bolt_rounded,
                child: isSmall
                    ? Column(children: [
                        BlastNumberField(blastNumber: blastNumber),
                        const SizedBox(height: 12),
                        BlastTypeDropdown(value: _blastType, onChanged: (v) => setState(() => _blastType = v ?? 'bore')),
                        const SizedBox(height: 12),
                        DatePickerField(date: _blastDate, dateFormat: _dateFormat, onTap: _pickDate),
                      ])
                    : Row(children: [
                        Expanded(child: BlastNumberField(blastNumber: blastNumber)),
                        const SizedBox(width: 14),
                        Expanded(child: BlastTypeDropdown(value: _blastType, onChanged: (v) => setState(() => _blastType = v ?? 'bore'))),
                        const SizedBox(width: 14),
                        Expanded(child: DatePickerField(date: _blastDate, dateFormat: _dateFormat, onTap: _pickDate)),
                      ]),
              ),
              const SizedBox(height: 14),

              // Section 2 — Drilling Financial
              BlastFormCard(
                title: 'Drilling Details',
                icon: Icons.construction_rounded,
                child: isSmall
                    ? Column(children: [
                        FormTextField(controller: _feetCtrl, label: 'Feet Drilled', hint: 'Enter feet', suffix: ' ft', prefixIcon: Icons.straighten_rounded, keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                        const SizedBox(height: 12),
                        FormTextField(controller: _rateCtrl, label: 'Rate per Feet', hint: '₹/ft', prefix: '₹ ', prefixIcon: Icons.price_change_rounded, keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                        if (_feet > 0 && _rate > 0) ...[
                          const SizedBox(height: 12),
                          DrillingCostPreview(feet: _feet, rate: _rate),
                        ],
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: FormTextField(controller: _feetCtrl, label: 'Feet Drilled', hint: 'Enter feet', suffix: ' ft', prefixIcon: Icons.straighten_rounded, keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                          const SizedBox(width: 14),
                          Expanded(child: FormTextField(controller: _rateCtrl, label: 'Rate per Feet', hint: '₹/ft', prefix: '₹ ', prefixIcon: Icons.price_change_rounded, keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                        ]),
                        if (_feet > 0 && _rate > 0) ...[
                          const SizedBox(height: 12),
                          DrillingCostPreview(feet: _feet, rate: _rate),
                        ],
                      ]),
              ),
              const SizedBox(height: 14),

              // Section 3 — Notes
              BlastFormCard(
                title: 'Notes',
                icon: Icons.notes_rounded,
                child: FormTextField(controller: _notesCtrl, label: '', hint: 'Add any additional notes...', maxLines: 3),
              ),
              const SizedBox(height: 28),

              SubmitButton(
                isLoading: _isLoading,
                text: _isEdit ? 'Update Blast' : 'Create Blast',
                onPressed: _submit,
              ),
            ]),
          ),
        )),
      ]),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _blastDate, firstDate: DateTime(2020), lastDate: appTodayIstDate());
    if (d != null) setState(() => _blastDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'blast_type': _blastType,
      'blast_date': appDateParam(_blastDate),
      'feet': double.parse(_feetCtrl.text),
      'rate': double.parse(_rateCtrl.text),
      'notes': _notesCtrl.text.trim(),
      'status': 'active',
    };

    final success = _isEdit
        ? await ref.read(blastProvider.notifier).updateBlast(widget.blastId!, data)
        : await ref.read(blastProvider.notifier).createBlast(data);

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Blast updated!' : 'Blast created!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }
}

// ─── Premium Gradient AppBar ───────────────────────────────────────────────────

class _BlastFormAppBar extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onBack;
  const _BlastFormAppBar({required this.isEdit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [_kAccent, _kAccentDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
          child: Row(children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
            const SizedBox(width: 4),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                child: Icon(isEdit ? Icons.edit_rounded : Icons.bolt_rounded, color: Colors.white, size: 16)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isEdit ? 'Edit Blast' : 'New Blast', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(isEdit ? 'Update blast information' : 'Create a new blast record', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}
