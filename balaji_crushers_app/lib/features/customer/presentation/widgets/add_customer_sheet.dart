import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/customer_provider.dart';

class AddCustomerSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddCustomerSheet({super.key, required this.onSave});

  static Future<void> show(BuildContext context, {required Function(Map<String, dynamic>) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomerSheet(onSave: onSave),
    );
  }

  @override
  ConsumerState<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<AddCustomerSheet> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String _customerType = 'individual';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final code = await ref.read(customerProvider.notifier).getNextCustomerCode();
      if (mounted) setState(() => _codeController.text = code);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSave({
        'customer_code': _codeController.text,
        'name': _nameController.text.trim(),
        'customer_type': _customerType,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'billing_address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
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
                const Text('Add Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormSection(
                    title: 'Basic Info',
                    icon: Icons.person_rounded,
                    children: [
                      _buildField(_codeController, 'Customer Code', Icons.tag_rounded, enabled: false),
                      const SizedBox(height: 12),
                      _buildField(_nameController, 'Full Name *', Icons.person_outline_rounded,
                          onChanged: (_) => setState(() {})),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _customerType,
                        decoration: _inputDecoration('Customer Type', Icons.category_rounded),
                        items: const [
                          DropdownMenuItem(value: 'individual', child: Text('Individual')),
                          DropdownMenuItem(value: 'company', child: Text('Company')),
                          DropdownMenuItem(value: 'government', child: Text('Government')),
                        ],
                        onChanged: (v) => setState(() => _customerType = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FormSection(
                    title: 'Contact',
                    icon: Icons.contact_phone_rounded,
                    children: [
                      Row(children: [
                        Expanded(child: _buildField(_phoneController, 'Phone', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(_emailController, 'Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                      ]),
                      const SizedBox(height: 12),
                      _buildField(_gstController, 'GST Number', Icons.receipt_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FormSection(
                    title: 'Address',
                    icon: Icons.location_on_rounded,
                    children: [
                      _buildField(_addressController, 'Billing Address', Icons.home_rounded, maxLines: 2),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _buildField(_cityController, 'City', Icons.location_city_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(_stateController, 'State', Icons.map_rounded)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Save button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isValid && !_isSubmitting ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSubmitting ? 'Saving...' : 'Add Customer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      onChanged: onChanged,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ─── Shared form section ───────────────────────────────────────────────────────

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
                  child: Icon(icon, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }
}