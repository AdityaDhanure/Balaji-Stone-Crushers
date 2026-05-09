import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';
import 'add_earning_dialog.dart' show earningInputDec, EarningDialogHeader, EarningFieldLabel;

class EditEarningDialog extends ConsumerStatefulWidget {
  final SalaryEarning earning;
  final Function()? onSuccess;

  const EditEarningDialog({super.key, required this.earning, this.onSuccess});

  static Future<void> show(BuildContext context,
      {required SalaryEarning earning, Function()? onSuccess}) {
    return showDialog(
      context: context,
      builder: (_) => EditEarningDialog(earning: earning, onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<EditEarningDialog> createState() => _EditEarningDialogState();
}

class _EditEarningDialogState extends ConsumerState<EditEarningDialog> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late TextEditingController _descController;
  bool _isLoading = false;

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hra':       return const Color(0xFF26A69A);
      case 'allowance': return AppColors.success;
      case 'bonus':     return AppColors.accent;
      default:          return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hra':       return Icons.home_outlined;
      case 'allowance': return Icons.account_balance_wallet_outlined;
      case 'bonus':     return Icons.star_outline_rounded;
      default:          return Icons.add_circle_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.earning.name);
    _valueController = TextEditingController(text: widget.earning.value.toString());
    _descController  = TextEditingController(text: widget.earning.description ?? '');
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
    final earn = widget.earning;
    final typeColor = _typeColor(earn.type);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EarningDialogHeader(
              icon: Icons.edit_outlined,
              title: 'Edit Earning',
              subtitle: 'Update earning component configuration',
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
                        Icon(_typeIcon(earn.type), size: 16, color: typeColor),
                        const SizedBox(width: 8),
                        Text(
                          '${earn.type.toUpperCase()} — ${earn.calculationType == 'percentage' ? 'Percentage' : 'Fixed'}',
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

                  EarningFieldLabel('Earning Name *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: earningInputDec('Earning name', prefixIcon: Icons.label_outline),
                  ),
                  const SizedBox(height: 14),

                  EarningFieldLabel('Description'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    decoration: earningInputDec('Optional description', prefixIcon: Icons.notes_outlined),
                  ),
                  const SizedBox(height: 14),

                  EarningFieldLabel(earn.calculationType == 'percentage' ? 'Percentage Value *' : 'Fixed Amount *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: earningInputDec(
                      earn.calculationType == 'percentage' ? 'e.g. 10' : 'e.g. 2000',
                      prefixIcon: earn.calculationType == 'percentage'
                          ? Icons.percent_rounded
                          : Icons.currency_rupee_rounded,
                      suffix: earn.calculationType == 'percentage' ? '%' : null,
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
      await ref.read(earningNotifierProvider.notifier).updateEarning(
        widget.earning.id!,
        name:            _nameController.text.trim(),
        type:            widget.earning.type,
        description:     _descController.text.isNotEmpty ? _descController.text.trim() : null,
        calculationType: widget.earning.calculationType,
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
