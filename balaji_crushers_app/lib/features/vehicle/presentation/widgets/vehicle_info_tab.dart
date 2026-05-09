import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

class VehicleInfoTab extends StatelessWidget {
  final dynamic vehicle;
  final Map<String, dynamic> stats;
  final bool isSmallScreen;

  const VehicleInfoTab({
    super.key,
    required this.vehicle,
    required this.stats,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        children: [
          _InfoRow(label: 'Vehicle Number', value: vehicle['vehicle_number'] ?? 'N/A'),
          _InfoRow(label: 'Vehicle Type', value: (vehicle['vehicle_type'] ?? '').toString().toUpperCase()),
          _InfoRow(label: 'Owner Name', value: vehicle['owner_name'] ?? 'N/A'),
          _InfoRow(label: 'Status', value: (vehicle['status'] ?? '').toString().toUpperCase()),
          _InfoRow(label: 'RTO EMI', value: vehicle['rto_emi_amount'] != null ? '₹${vehicle['rto_emi_amount']}' : 'N/A'),
          _InfoRow(label: 'EMI Due Date', value: appParseIstDate(vehicle['rto_emi_due_date']) != null ? dateFormat.format(appParseIstDate(vehicle['rto_emi_due_date'])!) : 'N/A'),
          _InfoRow(label: 'Odometer', value: '${vehicle['odometer_reading'] ?? 0} km'),
          _InfoRow(label: 'Usage Days', value: '${stats['usage_days'] ?? 0}'),
          if (vehicle['notes'] != null && vehicle['notes'].toString().isNotEmpty)
            _InfoRow(label: 'Notes', value: vehicle['notes'].toString()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }
}
