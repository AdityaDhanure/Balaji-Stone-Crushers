import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'settings_text_field.dart';
import 'settings_section_card.dart';

class CompanyInfoSection extends StatelessWidget {
  final Map<String, String> settings;
  final ValueChanged<Map<String, String>> onSettingsChanged;

  const CompanyInfoSection({
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
      title: 'Company Information',
      subtitle: 'Basic details shown on invoices & reports',
      icon: Icons.business_rounded,
      accentColor: AppColors.primary,
      children: [
        // ── Identity ────────────────────────────────────────────────────────
        SettingsTextField(
          label: 'Company Name',
          value: settings['company_name'] ?? '',
          prefixIcon: Icons.factory_rounded,
          hint: 'Balaji Stone Crushers',
          onChanged: (v) => _update('company_name', v),
        ),
        SettingsTextField(
          label: 'Address',
          value: settings['company_address'] ?? '',
          prefixIcon: Icons.location_on_rounded,
          hint: 'City, State',
          isMultiline: true,
          onChanged: (v) => _update('company_address', v),
        ),
        // Phone + Email side by side
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 480;
            final phone = SettingsTextField(
              label: 'Phone Number',
              value: settings['company_phone'] ?? '',
              prefixIcon: Icons.phone_rounded,
              hint: '10-digit mobile',
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (v) => _update('company_phone', v),
            );
            final email = SettingsTextField(
              label: 'Email Address',
              value: settings['company_email'] ?? '',
              prefixIcon: Icons.email_rounded,
              hint: 'info@company.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => _update('company_email', v),
            );
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: phone),
                const SizedBox(width: 12),
                Expanded(child: email),
              ]);
            }
            return Column(children: [phone, email]);
          },
        ),
        SettingsTextField(
          label: 'Website',
          value: settings['company_website'] ?? '',
          prefixIcon: Icons.language_rounded,
          hint: 'https://www.yourcompany.com',
          keyboardType: TextInputType.url,
          onChanged: (v) => _update('company_website', v),
        ),

        // ── Tax & Compliance ─────────────────────────────────────────────────
        const _SectionDivider(label: 'Tax & Compliance'),
        // GST + PAN
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 480;
            final gst = SettingsTextField(
              label: 'GST Number',
              value: settings['gst_number'] ?? '',
              prefixIcon: Icons.receipt_long_rounded,
              hint: '37AAACR1234P1Z5',
              maxLength: 15,
              onChanged: (v) => _update('gst_number', v.toUpperCase()),
            );
            final pan = SettingsTextField(
              label: 'PAN Number',
              value: settings['company_pan'] ?? '',
              prefixIcon: Icons.credit_card_rounded,
              hint: 'ABCDE1234F',
              maxLength: 10,
              onChanged: (v) => _update('company_pan', v.toUpperCase()),
            );
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: gst),
                const SizedBox(width: 12),
                Expanded(child: pan),
              ]);
            }
            return Column(children: [gst, pan]);
          },
        ),
        // State code + Currency
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 480;
            final stateCode = SettingsTextField(
              label: 'State Code (GST)',
              value: settings['company_state_code'] ?? '27',
              prefixIcon: Icons.map_rounded,
              hint: '27',
              maxLength: 2,
              helperText: 'e.g. 27 for Maharashtra',
              keyboardType: TextInputType.number,
              onChanged: (v) => _update('company_state_code', v),
            );
            final currency = SettingsTextField(
              label: 'Default Currency',
              value: settings['default_currency'] ?? 'INR',
              prefixIcon: Icons.currency_rupee_rounded,
              hint: 'INR',
              maxLength: 3,
              helperText: 'ISO 4217 code (INR, USD…)',
              onChanged: (v) => _update('default_currency', v.toUpperCase()),
            );
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: stateCode),
                const SizedBox(width: 12),
                Expanded(child: currency),
              ]);
            }
            return Column(children: [stateCode, currency]);
          },
        ),

        // ── Bank Details ─────────────────────────────────────────────────────
        const _SectionDivider(label: 'Bank Details'),
        SettingsTextField(
          label: 'Bank Name',
          value: settings['company_bank_name'] ?? '',
          prefixIcon: Icons.account_balance_rounded,
          hint: 'e.g. State Bank of India',
          onChanged: (v) => _update('company_bank_name', v),
        ),
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 480;
            final account = SettingsTextField(
              label: 'Account Number',
              value: settings['company_bank_account'] ?? '',
              prefixIcon: Icons.numbers_rounded,
              hint: '12-digit account number',
              keyboardType: TextInputType.number,
              onChanged: (v) => _update('company_bank_account', v),
            );
            final ifsc = SettingsTextField(
              label: 'IFSC Code',
              value: settings['company_bank_ifsc'] ?? '',
              prefixIcon: Icons.code_rounded,
              hint: 'SBIN0001234',
              maxLength: 11,
              onChanged: (v) => _update('company_bank_ifsc', v.toUpperCase()),
            );
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: account),
                const SizedBox(width: 12),
                Expanded(child: ifsc),
              ]);
            }
            return Column(children: [account, ifsc]);
          },
        ),
      ],
    );
  }
}

// ── Sub-section divider ───────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppColors.divider)),
        ],
      ),
    );
  }
}