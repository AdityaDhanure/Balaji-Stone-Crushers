import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'settings_text_field.dart';
import 'settings_section_card.dart';

class InvoiceSettingsSection extends StatelessWidget {
  final Map<String, String> settings;
  final ValueChanged<Map<String, String>> onSettingsChanged;

  const InvoiceSettingsSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  void _update(String key, String value) {
    final updated = Map<String, String>.from(settings);
    updated[key] = value;
    onSettingsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Invoice & Billing',
      subtitle: 'Customize how invoices are generated',
      icon: Icons.receipt_rounded,
      accentColor: const Color(0xFF8B5CF6), // purple
      children: [
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 480;
            final prefix = SettingsTextField(
              label: 'Invoice Prefix',
              value: settings['invoice_prefix'] ?? 'INV',
              prefixIcon: Icons.tag_rounded,
              hint: 'INV',
              maxLength: 6,
              helperText: 'e.g. INV → INV-0001',
              onChanged: (v) => _update('invoice_prefix', v.toUpperCase()),
            );
            final due = SettingsTextField(
              label: 'Payment Due Days',
              value: settings['invoice_due_days'] ?? '30',
              prefixIcon: Icons.schedule_rounded,
              hint: '30',
              keyboardType: TextInputType.number,
              helperText: 'Default days until invoice due',
              onChanged: (v) => _update('invoice_due_days', v),
            );
            final tax = SettingsTextField(
              label: 'Tax / GST Rate (%)',
              value: settings['invoice_tax_rate'] ?? '18',
              prefixIcon: Icons.percent_rounded,
              hint: '18',
              keyboardType: TextInputType.number,
              helperText: 'Default tax rate applied on invoices',
              onChanged: (v) => _update('invoice_tax_rate', v),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: prefix),
                  const SizedBox(width: 12),
                  Expanded(child: due),
                  const SizedBox(width: 12),
                  Expanded(child: tax),
                ],
              );
            }
            return Column(children: [prefix, due, tax]);
          },
        ),
        SettingsTextField(
          label: 'Invoice Terms & Conditions',
          value: settings['invoice_terms'] ?? '',
          prefixIcon: Icons.gavel_rounded,
          hint: 'Payment due within 30 days of invoice date.',
          isMultiline: true,
          onChanged: (v) => _update('invoice_terms', v),
        ),
        SettingsTextField(
          label: 'Invoice Footer Note',
          value: settings['invoice_footer'] ?? '',
          prefixIcon: Icons.sticky_note_2_rounded,
          hint: 'Thank you for your business!',
          isMultiline: true,
          onChanged: (v) => _update('invoice_footer', v),
        ),
      ],
    );
  }
}