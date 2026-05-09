import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/maintenance_provider.dart';
import 'common/status_badge.dart';
import 'common/maintenance_type_utils.dart';

/// Premium maintenance record card — modelled after Employee card.
class MaintenanceRecordCard extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MaintenanceRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final typeColor = getMaintenanceTypeColor(record.maintenanceType);
    final typeIcon = getMaintenanceTypeIcon(record.maintenanceType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 18),
                            ),
                            const SizedBox(width: 10),
                            // Main info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.typeDisplay,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    record.maintenanceTypeDisplay,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right side: cost + status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${fmt.format(record.cost)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                MaintenanceStatusBadge(status: record.status),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,
                                  size: 18,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.7)),
                              onSelected: (v) {
                                if (v == 'edit') onEdit();
                                if (v == 'delete') onDelete();
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit_rounded,
                                        size: 16, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('Edit',
                                        style: TextStyle(fontSize: 13)),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete_rounded,
                                        size: 16, color: AppColors.error),
                                    const SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.error)),
                                  ]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.description,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Bottom row: dates
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _fmtDate(record.maintenanceDate),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                            if (record.nextDueDate != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.event_rounded,
                                size: 12,
                                color: record.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${_fmtDate(record.nextDueDate!, short: true)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: record.isOverdue
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontWeight: record.isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (record.isOverdue) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error),
                                  ),
                                ),
                              ],
                            ],
                            if (record.vendorName != null) ...[
                              const Spacer(),
                              const Icon(Icons.business_rounded,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  record.vendorName!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String raw, {bool short = false}) {
    try {
      final d = appParseIstDate(raw);
      if (d == null) return '—';
      return short
          ? '${d.day} ${_months[d.month - 1]}'
          : '${d.day} ${_months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
