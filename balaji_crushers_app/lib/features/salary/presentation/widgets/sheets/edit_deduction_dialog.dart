import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';
import 'add_deduction_dialog.dart' show _inputDec, _FieldLabel, _DialogHeader;

class EditDeductionDialog extends ConsumerStatefulWidget {
  final SalaryDeduction deduction;
  final Function()? onSuccess;

  const EditDeductionDialog({super.key, required this.deduction, this.onSuccess});

  static Future<void> show(BuildContext context,
      {required SalaryDeduction deduction, Function()? onSuccess}) {
    return showDialog(
      context: context,
      builder: (_) => EditDeductionDialog(deduction: deduction, onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<EditDeductionDialog> createState() => _EditDeductionDialogState();
}

class _EditDeductionDialogState extends ConsumerState<EditDeductionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late TextEditingController _descController;
  bool _isLoading = false;

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pf':  return const Color(0xFF6C63FF);
      case 'tds': return AppColors.warning;
      case 'esi': return AppColors.info;
      default:    return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pf':  return Icons.account_balance_outlined;
      case 'tds': return Icons.receipt_long_outlined;
      case 'esi': return Icons.health_and_safety_outlined;
      default:    return Icons.remove_circle_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.deduction.name);
    _valueController = TextEditingController(text: widget.deduction.value.toString());
    _descController  = TextEditingController(text: widget.deduction.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ded = widget.deduction;
    final typeColor = _typeColor(ded.type);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.edit_outlined,
              title: 'Edit Deduction',
              subtitle: 'Update deduction configuration',
              color: typeColor,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge (read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: typeColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon(ded.type), size: 16, color: typeColor),
                        const SizedBox(width: 8),
                        Text(
                          '${ded.type.toUpperCase()} — ${ded.calculationType == 'percentage' ? 'Percentage' : 'Fixed'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Read-only',
                            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FieldLabel('Deduction Name *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDec('Deduction name', prefixIcon: Icons.label_outline),
                  ),
                  const SizedBox(height: 14),

                  _FieldLabel('Description'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    decoration: _inputDec('Optional description', prefixIcon: Icons.notes_outlined),
                  ),
                  const SizedBox(height: 14),

                  _FieldLabel(ded.calculationType == 'percentage' ? 'Percentage Value *' : 'Fixed Amount *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec(
                      ded.calculationType == 'percentage' ? 'e.g. 12' : 'e.g. 500',
                      prefixIcon: ded.calculationType == 'percentage'
                          ? Icons.percent_rounded
                          : Icons.currency_rupee_rounded,
                      suffixText: ded.calculationType == 'percentage' ? '%' : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(deductionNotifierProvider.notifier).updateDeduction(
        widget.deduction.id!,
        name:            _nameController.text.trim(),
        type:            widget.deduction.type,
        description:     _descController.text.isNotEmpty ? _descController.text.trim() : null,
        calculationType: widget.deduction.calculationType,
        value:           double.tryParse(_valueController.text) ?? 0,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Add at bottom of each affected file ──────────────────────────

class _DialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _DialogHeader({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _FieldLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    ),
  );
}

InputDecoration _inputDec(
  String hint, {
  String? prefixText,
  String? suffixText,
  IconData? prefixIcon,
  IconData? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
    prefixText: prefixText,
    suffixText: suffixText,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
        : null,
    suffixIcon: suffixIcon != null
        ? Icon(suffixIcon, size: 18, color: AppColors.textSecondary)
        : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade50,
  );
}