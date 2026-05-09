import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';

class PeriodSelector extends ConsumerWidget {
  final SalaryPeriod? selectedPeriod;
  final ValueChanged<SalaryPeriod?> onPeriodChanged;
  final VoidCallback onCreatePeriod;
  final VoidCallback onGenerateIndividual;
  final VoidCallback onBulkGenerate;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onCreatePeriod,
    required this.onGenerateIndividual,
    required this.onBulkGenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(periodsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Period icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),

          // Dropdown
          Expanded(
            child: periodsAsync.when(
              data: (periods) => Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppColors.surface,
                ),
                child: DropdownButtonFormField<SalaryPeriod>(
                  value: selectedPeriod,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Salary Period',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    filled: true,
                  ),
                  iconEnabledColor: Colors.white,
                  items: periods.map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Text(
                          p.monthName,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                        if (p.isLocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock, size: 14, color: AppColors.error),
                        ],
                      ],
                    ),
                  )).toList(),
                  onChanged: onPeriodChanged,
                ),
              ),
              loading: () => const LinearProgressIndicator(color: Colors.white),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons
          _ActionIconButton(
            icon: Icons.add_circle_outline,
            tooltip: 'Create Period',
            onPressed: onCreatePeriod,
          ),
          if (selectedPeriod != null) ...[
            const SizedBox(width: 4),
            _ActionIconButton(
              icon: Icons.person_add_outlined,
              tooltip: 'Generate Individual Slip',
              onPressed: onGenerateIndividual,
            ),
            const SizedBox(width: 4),
            _ActionIconButton(
              icon: Icons.auto_awesome,
              tooltip: 'Bulk Generate All',
              onPressed: onBulkGenerate,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlight;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}