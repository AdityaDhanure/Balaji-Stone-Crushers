import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'settings_text_field.dart';
import 'settings_section_card.dart';

class AlertThresholdsSection extends StatelessWidget {
  final Map<String, String> settings;
  final ValueChanged<Map<String, String>> onSettingsChanged;

  const AlertThresholdsSection({
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
      title: 'Alerts & Thresholds',
      subtitle: 'Configure when system notifications are triggered',
      icon: Icons.notifications_active_rounded,
      accentColor: AppColors.warning,
      children: [
        _AlertRow(
          icon: Icons.local_gas_station_rounded,
          iconColor: const Color(0xFFEF4444),
          label: 'Low Diesel Alert',
          description: 'Trigger alert when diesel stock falls below this level',
          child: SettingsTextField(
            label: 'Threshold (Litres)',
            value: settings['low_diesel_threshold'] ?? '500',
            keyboardType: TextInputType.number,
            hint: '500',
            onChanged: (v) => _update('low_diesel_threshold', v),
          ),
        ),
        const _Divider(),
        _AlertRow(
          icon: Icons.description_rounded,
          iconColor: const Color(0xFF3B82F6),
          label: 'Vehicle Document Expiry',
          description: 'Alert when a vehicle document expires within these days',
          child: SettingsTextField(
            label: 'Days Before Expiry',
            value: settings['vehicle_document_alert_days'] ?? '30',
            keyboardType: TextInputType.number,
            hint: '30',
            onChanged: (v) => _update('vehicle_document_alert_days', v),
          ),
        ),
        const _Divider(),
        _AlertRow(
          icon: Icons.build_rounded,
          iconColor: const Color(0xFF8B5CF6),
          label: 'Maintenance Due Alert',
          description: 'Alert when maintenance is due within these days',
          child: SettingsTextField(
            label: 'Days Before Due',
            value: settings['maintenance_alert_days'] ?? '7',
            keyboardType: TextInputType.number,
            hint: '7',
            onChanged: (v) => _update('maintenance_alert_days', v),
          ),
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final Widget child;

  const _AlertRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2, right: 14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(width: 180, child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.divider,
    );
  }
}