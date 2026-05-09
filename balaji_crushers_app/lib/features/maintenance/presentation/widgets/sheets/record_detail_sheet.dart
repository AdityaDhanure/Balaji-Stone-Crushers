import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/ist_date_utils.dart';
import '../../providers/maintenance_provider.dart';
import '../common/maintenance_type_utils.dart';
import '../common/status_badge.dart';

/// Rich, premium detail sheet for a maintenance record.
class RecordDetailSheet extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback? onEdit;

  const RecordDetailSheet({
    super.key,
    required this.record,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final typeColor = getMaintenanceTypeColor(record.maintenanceType);
    final typeIcon = getMaintenanceTypeIcon(record.maintenanceType);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Gradient header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  typeColor.withValues(alpha: 0.15),
                  typeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: typeColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.maintenanceTypeDisplay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        record.typeDisplay,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${fmt.format(record.cost)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MaintenanceStatusBadge(status: record.status),
                  ],
                ),
              ],
            ),
          ),
          // Details
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Details'),
                  const SizedBox(height: 8),
                  _DetailCard(
                    rows: [
                      _Row(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: _fmt(record.maintenanceDate)),
                      if (record.nextDueDate != null)
                        _Row(
                            icon: Icons.event_rounded,
                            label: 'Next Due',
                            value: _fmt(record.nextDueDate!),
                            valueColor:
                                record.isOverdue ? AppColors.error : null),
                      _Row(
                          icon: Icons.person_rounded,
                          label: 'Logged By',
                          value: record.createdByName ?? '—'),
                    ],
                  ),
                  if (record.vendorName != null) ...[
                    const SizedBox(height: 14),
                    _SectionLabel(label: 'Vendor'),
                    const SizedBox(height: 8),
                    _DetailCard(
                      rows: [
                        _Row(
                            icon: Icons.business_rounded,
                            label: 'Name',
                            value: record.vendorName!),
                        if (record.vendorPhone != null)
                          _Row(
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              value: record.vendorPhone!),
                      ],
                    ),
                  ],
                  if (record.partsReplaced != null &&
                      record.partsReplaced!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionLabel(label: 'Parts Used'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        record.partsReplaced!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SectionLabel(label: 'Description'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      record.description,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (onEdit != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit!();
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Record'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String raw) {
    try {
      final d = appParseIstDate(raw);
      if (d == null) return '—';
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ─── sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );
}

class _Row {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _DetailCard extends StatelessWidget {
  final List<_Row> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final row = e.value;
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(row.icon,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: row.valueColor ?? AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                    color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}
