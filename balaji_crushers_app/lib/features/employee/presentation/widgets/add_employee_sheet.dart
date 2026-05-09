import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/employee_provider.dart';

class AddEmployeeSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddEmployeeSheet({super.key, required this.onSave});

  @override
  ConsumerState<AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _designationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _addressController = TextEditingController();

  int? _selectedDepartmentId;
  String _employeeType = 'permanent';
  DateTime _dateOfJoining = appTodayIstDate();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(employeeProvider.notifier).loadDepartments();
      final code = await ref.read(employeeProvider.notifier).getNextEmployeeCode();
      if (mounted) _codeController.text = code;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _upiIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('First name is required');
      return;
    }
    setState(() => _isSaving = true);
    await widget.onSave({
      'employee_code': _codeController.text,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'department_id': _selectedDepartmentId,
      'designation': _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
      'employee_type': _employeeType,
      'date_of_joining': appDateParam(_dateOfJoining),
      'salary': double.tryParse(_salaryController.text) ?? 0,
      'aadhaar_number': _aadhaarController.text.trim().isEmpty ? null : _aadhaarController.text.trim(),
      'pan_number': _panController.text.trim().isEmpty ? null : _panController.text.trim(),
      'upi_id': _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    });
    if (mounted) setState(() => _isSaving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(employeeProvider).departments;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Add Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormSection(
                      title: 'Basic Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _buildField(_codeController, 'Employee Code', enabled: false, icon: Icons.badge_outlined),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildField(_firstNameController, 'First Name *', icon: Icons.person_outline)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(_lastNameController, 'Last Name', icon: Icons.person_outline)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildField(_phoneController, 'Phone', icon: Icons.phone_outlined, keyboard: TextInputType.phone)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(_emailController, 'Email', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Employment Details',
                      icon: Icons.work_outline_rounded,
                      children: [
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedDepartmentId,
                              decoration: _inputDecoration('Department', Icons.business_outlined),
                              items: departments.map<DropdownMenuItem<int>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedDepartmentId = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(_designationController, 'Designation', icon: Icons.work_outline)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _employeeType,
                              decoration: _inputDecoration('Employee Type', Icons.category_outlined),
                              items: const [
                                DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                                DropdownMenuItem(value: 'contract', child: Text('Contract')),
                                DropdownMenuItem(value: 'daily', child: Text('Daily Wager')),
                              ],
                              onChanged: (v) => setState(() => _employeeType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfJoining,
                                  firstDate: DateTime(2010),
                                  lastDate: appTodayIstDate(),
                                );
                                if (picked != null) setState(() => _dateOfJoining = picked);
                              },
                              child: InputDecorator(
                                decoration: _inputDecoration('Joining Date', Icons.calendar_today_outlined),
                                child: Text(DateFormat('dd MMM yyyy').format(_dateOfJoining), style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _buildField(_salaryController, 'Monthly Salary (₹)', icon: Icons.currency_rupee_outlined, keyboard: TextInputType.number, prefix: '₹ '),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Identity & Payment',
                      icon: Icons.credit_card_outlined,
                      children: [
                        Row(children: [
                          Expanded(child: _buildField(_aadhaarController, 'Aadhaar Number', icon: Icons.credit_card_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(_panController, 'PAN Number', icon: Icons.badge_outlined)),
                        ]),
                        const SizedBox(height: 12),
                        _buildField(_upiIdController, 'UPI ID', icon: Icons.payments_outlined),
                        const SizedBox(height: 12),
                        _buildField(_addressController, 'Address', icon: Icons.location_on_outlined, maxLines: 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Save button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_rounded, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Add Employee', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {
    bool enabled = true,
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration(label, icon, prefix: prefix),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.textSecondary) : null,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ─── FormSection widget ─────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 15, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}
