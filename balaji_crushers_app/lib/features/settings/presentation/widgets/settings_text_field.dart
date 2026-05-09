import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final bool isMultiline;
  final int? maxLength;
  final String? Function(String?)? validator;

  const SettingsTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.isMultiline = false,
    this.maxLength,
    this.validator,
  });

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SettingsTextField old) {
    super.didUpdateWidget(old);
    // Sync only if the parent changed the value externally (not from user typing)
    if (!_isDirty && old.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controller,
        keyboardType: widget.isMultiline
            ? TextInputType.multiline
            : widget.keyboardType,
        maxLines: widget.isMultiline ? 3 : 1,
        maxLength: widget.maxLength,
        validator: widget.validator,
        style: const TextStyle(
          fontSize: 13.5,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helperText,
          helperMaxLines: 2,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 17, color: AppColors.textSecondary)
              : null,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefixIcon != null ? 8 : 14,
            vertical: widget.isMultiline ? 12 : 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          counterText: '',
        ),
        onChanged: (v) {
          _isDirty = true;
          widget.onChanged(v);
        },
      ),
    );
  }
}