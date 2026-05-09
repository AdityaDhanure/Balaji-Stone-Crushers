import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

// Accent colour for blast section — deep orange/amber
const _kBlastAccent = Color(0xFFE67E22);
const _kBlastAccentDark = Color(0xFFD35400);

// ─── Section Card ──────────────────────────────────────────────────────────────

class BlastFormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  // Legacy compat — ignored
  final bool isSmallScreen;

  const BlastFormCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kBlastAccent, _kBlastAccentDark]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.2)),
          ]),
          const SizedBox(height: 4),
          Divider(color: AppColors.border.withValues(alpha: 0.6), height: 20),
          child,
        ]),
      ),
    );
  }
}

// ─── Blast Number Badge ────────────────────────────────────────────────────────

class BlastNumberField extends StatelessWidget {
  final String blastNumber;
  const BlastNumberField({super.key, required this.blastNumber, bool isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Blast Number', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _kBlastAccent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBlastAccent.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.bolt_rounded, color: _kBlastAccent, size: 16),
          const SizedBox(width: 8),
          Text('# $blastNumber', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kBlastAccent)),
          const Spacer(),
          const Text('Auto', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    ]);
  }
}

// ─── Blast Type Selector ───────────────────────────────────────────────────────

class BlastTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const BlastTypeDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Blast Type', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.category_rounded, size: 18, color: _kBlastAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlastAccent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
        items: const [
          DropdownMenuItem(value: 'bore', child: Row(children: [Icon(Icons.radio_button_unchecked_rounded, size: 16, color: _kBlastAccent), SizedBox(width: 8), Text('Bore Blast')])),
          DropdownMenuItem(value: 'tractor', child: Row(children: [Icon(Icons.agriculture_rounded, size: 16, color: _kBlastAccent), SizedBox(width: 8), Text('Tractor Blast')])),
        ],
        onChanged: onChanged,
      ),
    ]);
  }
}

// ─── Date Picker Field ─────────────────────────────────────────────────────────

class DatePickerField extends StatelessWidget {
  final DateTime date;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  const DatePickerField({super.key, required this.date, required this.dateFormat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Blast Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            color: AppColors.background,
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: _kBlastAccent),
            const SizedBox(width: 10),
            Text(dateFormat.format(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.textSecondary),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Text Field ────────────────────────────────────────────────────────────────

class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final String? prefix;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.prefix,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) ...[
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
      ],
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
          prefixText: prefix,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: _kBlastAccent) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlastAccent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    ]);
  }
}

// ─── Live Cost Preview ─────────────────────────────────────────────────────────

class DrillingCostPreview extends StatelessWidget {
  final double feet;
  final double rate;
  const DrillingCostPreview({super.key, required this.feet, required this.rate});

  @override
  Widget build(BuildContext context) {
    final cost = feet * rate;
    if (feet <= 0 || rate <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kBlastAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBlastAccent.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.calculate_rounded, color: _kBlastAccent, size: 16),
        const SizedBox(width: 8),
        const Text('Drilling Cost: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text('₹${NumberFormat('#,##,###').format(cost)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _kBlastAccent)),
        const Spacer(),
        Text('$feet ft × ₹$rate', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ─── Submit Button ─────────────────────────────────────────────────────────────

class SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback onPressed;
  const SubmitButton({super.key, required this.isLoading, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isLoading ? null : const LinearGradient(colors: [_kBlastAccent, _kBlastAccentDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: isLoading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading ? null : [BoxShadow(color: _kBlastAccent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent, borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(child: isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ])),
            ),
          ),
        ),
      ),
    );
  }
}