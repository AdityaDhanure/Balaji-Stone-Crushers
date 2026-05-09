import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/core/utils/ist_date_utils.dart';
import 'package:balaji_crushers_app/features/salary/data/repositories/salary_repository.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';
import 'add_deduction_dialog.dart' show _DialogHeader;

class CreatePeriodDialog extends ConsumerStatefulWidget {
  final Function()? onSuccess;

  const CreatePeriodDialog({super.key, this.onSuccess});

  static Future<void> show(BuildContext context, {Function()? onSuccess}) {
    return showDialog(
      context: context,
      builder: (_) => CreatePeriodDialog(onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<CreatePeriodDialog> createState() => _CreatePeriodDialogState();
}

class _CreatePeriodDialogState extends ConsumerState<CreatePeriodDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  bool _isLoading = false;

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  @override
  void initState() {
    super.initState();
    final now = appTodayIstDate();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  String get _previewRange {
    final start = DateTime(_selectedYear, _selectedMonth, 1);
    final end   = DateTime(_selectedYear, _selectedMonth + 1, 0);
    return '${DateFormat('dd MMM yyyy').format(start)} — ${DateFormat('dd MMM yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(5, (i) => appTodayIstDate().year - 2 + i);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.calendar_month_rounded,
              title: 'Create Salary Period',
              subtitle: 'Select month and year to create a new period',
              color: AppColors.primary,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Year & Month row
                  Row(
                    children: [
                      // Year dropdown
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _selectedYear,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
                              ),
                              items: years.map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedYear = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Month dropdown
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _selectedMonth,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              items: List.generate(12, (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(_monthNames[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                              )),
                              onChanged: (v) => setState(() => _selectedMonth = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primaryLight.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.preview_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'Period Preview',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _previewRange,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
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
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _create,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create Period', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
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

  Future<void> _create() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(salaryRepositoryProvider);
      await repo.createPeriod(_selectedYear, _selectedMonth);
      ref.invalidate(periodsProvider);
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
