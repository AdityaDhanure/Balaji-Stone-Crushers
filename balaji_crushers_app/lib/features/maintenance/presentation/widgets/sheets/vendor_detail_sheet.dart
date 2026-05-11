import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../providers/maintenance_provider.dart';

class VendorDetailSheet extends ConsumerStatefulWidget {
  final Vendor vendor;
  final VoidCallback onUpdate;

  const VendorDetailSheet({
    super.key,
    required this.vendor,
    required this.onUpdate,
  });

  @override
  ConsumerState<VendorDetailSheet> createState() => _VendorDetailSheetState();
}

class _VendorDetailSheetState extends ConsumerState<VendorDetailSheet> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _specializationController;
  late TextEditingController _addressController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final v = widget.vendor;
    _nameController = TextEditingController(text: v.name);
    _contactController = TextEditingController(text: v.contactPerson ?? '');
    _phoneController = TextEditingController(text: v.phone ?? '');
    _emailController = TextEditingController(text: v.email ?? '');
    _specializationController =
        TextEditingController(text: v.specialization ?? '');
    _addressController = TextEditingController(text: v.address ?? '');
    _isActive = v.isActive;
  }

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
    final v = widget.vendor;
    final initials = v.name.isNotEmpty ? v.name.trim()[0].toUpperCase() : 'V';

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
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (v.specialization != null)
                        Text(
                          v.specialization!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (v.isActive ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (v.isActive ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    v.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: v.isActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _isEditing = !_isEditing),
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
                : _buildDetailView(context),
          ),
          if (_isEditing) _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final v = widget.vendor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Contact Info'),
          const SizedBox(height: 8),
          _DetailCard(rows: [
            if (v.contactPerson != null)
              _Row(icon: Icons.person_rounded, label: 'Contact', value: v.contactPerson!),
            if (v.phone != null)
              _Row(icon: Icons.phone_rounded, label: 'Phone', value: v.phone!),
            if (v.email != null)
              _Row(icon: Icons.email_rounded, label: 'Email', value: v.email!),
            if (v.address != null)
              _Row(icon: Icons.location_on_rounded, label: 'Address', value: v.address!),
          ]),
          const SizedBox(height: 20),
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
                      .deleteVendor(widget.vendor.id);
                }
              },
              icon: const Icon(Icons.delete_rounded,
                  size: 16, color: AppColors.error),
              label: const Text('Delete Vendor',
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
          _field(_nameController, 'Vendor name', Icons.business_rounded,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _label('Contact Person'),
          const SizedBox(height: 8),
          _field(_contactController, 'Full name', Icons.person_rounded),
          const SizedBox(height: 12),
          _label('Phone'),
          const SizedBox(height: 8),
          _field(_phoneController, 'Phone number', Icons.phone_rounded,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _label('Email'),
          const SizedBox(height: 8),
          _field(_emailController, 'Email address', Icons.email_rounded,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _label('Specialization'),
          const SizedBox(height: 8),
          _field(_specializationController, 'e.g. Hydraulics',
              Icons.construction_rounded),
          const SizedBox(height: 12),
          _label('Address'),
          const SizedBox(height: 8),
          _field(_addressController, 'Full address',
              Icons.location_on_rounded,
              maxLines: 2),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title:
                  const Text('Active', style: TextStyle(fontSize: 14)),
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
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    final ok = await ref.read(maintenanceProvider.notifier).updateVendor(
      widget.vendor.id,
      {
        'name': _nameController.text,
        'contact_person': _contactController.text.isEmpty
            ? null
            : _contactController.text,
        'phone':
            _phoneController.text.isEmpty ? null : _phoneController.text,
        'email':
            _emailController.text.isEmpty ? null : _emailController.text,
        'specialization': _specializationController.text.isEmpty
            ? null
            : _specializationController.text,
        'address': _addressController.text.isEmpty
            ? null
            : _addressController.text,
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

  Future<bool?> _showDeleteConfirm(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Vendor'),
          content:
              Text('Delete "${widget.vendor.name}"? This cannot be undone.'),
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

// ─── Detail card ──────────────────────────────────────────────────────────────
class _Row {
  final IconData icon;
  final String label;
  final String value;
  const _Row(
      {required this.icon, required this.label, required this.value});
}

class _DetailCard extends StatelessWidget {
  final List<_Row> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('No contact info available',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
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
                      width: 80,
                      child: Text(row.label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
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
