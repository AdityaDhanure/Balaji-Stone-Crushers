import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

// ─── Section Card ──────────────────────────────────────────────────────────────

class VehicleFormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const VehicleFormCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    // legacy compat — ignored
    bool isSmallScreen = false,
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
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.2)),
          ]),
          const SizedBox(height: 4),
          Divider(color: AppColors.border.withValues(alpha: 0.6), height: 20),
          ...children,
        ]),
      ),
    );
  }
}

// ─── Text Field ────────────────────────────────────────────────────────────────

class VehicleFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final String? prefix;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const VehicleFormTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.prefix,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixText: prefix,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
      validator: validator,
    );
  }
}

// ─── Type Dropdown ─────────────────────────────────────────────────────────────

class VehicleTypeDropdown extends StatelessWidget {
  final String value;
  final List<String> vehicleTypes;
  final Function(String?) onChanged;

  const VehicleTypeDropdown({
    super.key,
    required this.value,
    required this.vehicleTypes,
    required this.onChanged,
  });

  static IconData iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'truck': case 'hyva': return Icons.local_shipping_rounded;
      case 'tractor': return Icons.agriculture_rounded;
      case 'jcb': return Icons.construction_rounded;
      case 'loader': return Icons.precision_manufacturing_rounded;
      case 'pockland': return Icons.landscape_rounded;
      case 'roller': return Icons.tire_repair_rounded;
      case 'paver': return Icons.layers_rounded;
      case 'water tanker': return Icons.water_drop_rounded;
      default: return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: Icon(iconFor(value), size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
      items: vehicleTypes.map((t) => DropdownMenuItem(
        value: t.toLowerCase(),
        child: Row(children: [
          Icon(iconFor(t), size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(fontSize: 13)),
        ]),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Date Picker Field ─────────────────────────────────────────────────────────

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat dateFormat;
  final Function(DateTime?) onChanged;

  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.dateFormat,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = value != null;
    final daysLeft = hasDate ? value!.difference(appTodayIstDate()).inDays : null;
    final isExpiring = daysLeft != null && daysLeft >= 0 && daysLeft <= 30;
    final isExpired = daysLeft != null && daysLeft < 0;
    final statusColor = isExpired ? AppColors.error : isExpiring ? AppColors.warning : AppColors.primary;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? appTodayIstDate().add(const Duration(days: 365)),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate ? statusColor.withValues(alpha: 0.05) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasDate ? statusColor.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: hasDate ? statusColor : AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(child: Text(
              hasDate ? dateFormat.format(value!) : 'Tap to set date',
              style: TextStyle(fontSize: 12, fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal, color: hasDate ? statusColor : AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            )),
            if (hasDate)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close_rounded, size: 14, color: statusColor.withValues(alpha: 0.7)),
              ),
          ]),
          if (hasDate && (isExpired || isExpiring))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(isExpired ? 'EXPIRED' : 'Exp. in $daysLeft days',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.3)),
            ),
        ]),
      ),
    );
  }
}

// ─── Document Info Banner ──────────────────────────────────────────────────────

class DocumentExpiryInfo extends StatelessWidget {
  const DocumentExpiryInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.info),
        SizedBox(width: 8),
        Expanded(child: Text('Leave empty if not applicable. Expiring dates are highlighted automatically.', style: TextStyle(fontSize: 11, color: AppColors.info))),
      ]),
    );
  }
}

// ─── Submit Button ─────────────────────────────────────────────────────────────

class SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback? onPressed;

  const SubmitButton({super.key, required this.isLoading, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isLoading ? null : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: isLoading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading ? null : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
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
