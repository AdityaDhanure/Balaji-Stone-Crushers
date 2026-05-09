import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';


/// Add a new vendor.
class AddVendorSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddVendorSheet({super.key, required this.onSave});

  @override
  State<AddVendorSheet> createState() => _AddVendorSheetState();
}

class _AddVendorSheetState extends State<AddVendorSheet> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Vendor',
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
                  _label('Vendor Name *'),
                  const SizedBox(height: 8),
                  _field(_nameController, 'e.g. Raj Hydraulics',
                      Icons.business_rounded,
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  _label('Contact Person'),
                  const SizedBox(height: 8),
                  _field(_contactController, 'Full name',
                      Icons.person_rounded),
                  const SizedBox(height: 12),
                  _label('Phone'),
                  const SizedBox(height: 8),
                  _field(_phoneController, '+91 9876543210',
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _label('Email'),
                  const SizedBox(height: 8),
                  _field(_emailController, 'vendor@example.com',
                      Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _label('Specialization'),
                  const SizedBox(height: 8),
                  _field(_specializationController,
                      'e.g. Hydraulics, Electrical', Icons.construction_rounded),
                  const SizedBox(height: 12),
                  _label('Address'),
                  const SizedBox(height: 8),
                  _field(_addressController, 'Street, City…',
                      Icons.location_on_rounded,
                      maxLines: 2),
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
                            color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'ADD VENDOR',
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
      'contact_person':
          _contactController.text.isEmpty ? null : _contactController.text,
      'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
      'email': _emailController.text.isEmpty ? null : _emailController.text,
      'specialization': _specializationController.text.isEmpty
          ? null
          : _specializationController.text,
      'address':
          _addressController.text.isEmpty ? null : _addressController.text,
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

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
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
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}