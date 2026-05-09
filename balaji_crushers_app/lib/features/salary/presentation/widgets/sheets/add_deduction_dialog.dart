import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';

class AddDeductionDialog extends ConsumerStatefulWidget {
  final Function()? onSuccess;

  const AddDeductionDialog({super.key, this.onSuccess});

  static Future<void> show(BuildContext context, {Function()? onSuccess}) {
    return showDialog(
      context: context,
      builder: (_) => AddDeductionDialog(onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<AddDeductionDialog> createState() => _AddDeductionDialogState();
}

class _AddDeductionDialogState extends ConsumerState<AddDeductionDialog> {
  final _nameController  = TextEditingController();
  final _descController  = TextEditingController();
  final _valueController = TextEditingController();
  String _deductionType   = 'pf';
  String _calculationType = 'percentage';
  bool _isLoading = false;

  static const _types = [
    ('pf',    'PF',    Icons.account_balance_outlined,    Color(0xFF6C63FF)),
    ('tds',   'TDS',   Icons.receipt_long_outlined,       AppColors.warning),
    ('esi',   'ESI',   Icons.health_and_safety_outlined,  AppColors.info),
    ('other', 'Other', Icons.remove_circle_outline,       AppColors.textSecondary),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _DialogHeader(
              icon: Icons.add_circle_outline_rounded,
              title: 'Add Deduction',
              subtitle: 'Configure a new salary deduction rule',
              color: AppColors.primary,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _FieldLabel('Deduction Name *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDec('e.g. Provident Fund', prefixIcon: Icons.label_outline),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  _FieldLabel('Description'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    decoration: _inputDec('Optional description', prefixIcon: Icons.notes_outlined),
                  ),
                  const SizedBox(height: 14),

                  // Type selector chips
                  _FieldLabel('Deduction Type *'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _types.map((t) {
                      final isSelected = _deductionType == t.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _deductionType = t.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? t.$4.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? t.$4 : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.$3, size: 14, color: isSelected ? t.$4 : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                t.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? t.$4 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Calculation type toggle
                  _FieldLabel('Calculation Method *'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        _CalcTypeBtn(
                          label: 'Percentage %',
                          icon: Icons.percent_rounded,
                          selected: _calculationType == 'percentage',
                          onTap: () => setState(() => _calculationType = 'percentage'),
                        ),
                        _CalcTypeBtn(
                          label: 'Fixed ₹',
                          icon: Icons.currency_rupee_rounded,
                          selected: _calculationType == 'fixed',
                          onTap: () => setState(() => _calculationType = 'fixed'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Value
                  _FieldLabel(_calculationType == 'percentage' ? 'Percentage Value *' : 'Fixed Amount *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec(
                      _calculationType == 'percentage' ? 'e.g. 12' : 'e.g. 500',
                      prefixIcon: _calculationType == 'percentage'
                          ? Icons.percent_rounded
                          : Icons.currency_rupee_rounded,
                      suffix: _calculationType == 'percentage' ? '%' : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
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
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Add Deduction', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(deductionNotifierProvider.notifier).createDeduction(
        name:            _nameController.text.trim(),
        type:            _deductionType,
        description:     _descController.text.isNotEmpty ? _descController.text.trim() : null,
        calculationType: _calculationType,
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

// ─── shared helpers ──────────────────────────────────────────────────

InputDecoration _inputDec(String hint, {IconData? prefixIcon, String? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary) : null,
    suffixText: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    isDense: true,
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      letterSpacing: 0.2,
    ),
  );
}

class _CalcTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CalcTypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}