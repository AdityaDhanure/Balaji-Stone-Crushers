import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

class VehicleDocumentsTab extends StatelessWidget {
  final dynamic vehicle;
  final bool isSmallScreen;

  const VehicleDocumentsTab({
    super.key,
    required this.vehicle,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final documents = [
      {'name': 'Insurance', 'date': vehicle['insurance_expiry'], 'icon': Icons.security_rounded},
      {'name': 'PUC', 'date': vehicle['puc_expiry'], 'icon': Icons.eco_rounded},
      {'name': 'Passing', 'date': vehicle['passing_expiry'], 'icon': Icons.verified_rounded},
      {'name': 'Road Tax', 'date': vehicle['road_tax_expiry'], 'icon': Icons.receipt_long_rounded},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final date = appParseIstDate(doc['date']);
        final isExpiring = _isExpiringSoon(date);
        final isExpired = _isExpired(date);

        return _DocumentCard(
          name: doc['name'] as String,
          date: date,
          icon: doc['icon'] as IconData,
          isExpiring: isExpiring,
          isExpired: isExpired,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  bool _isExpiringSoon(DateTime? date) {
    if (date == null) return false;
    final daysUntilExpiry = date.difference(appTodayIstDate()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool _isExpired(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(appTodayIstDate());
  }
}

class _DocumentCard extends StatelessWidget {
  final String name;
  final DateTime? date;
  final IconData icon;
  final bool isExpiring;
  final bool isExpired;
  final bool isSmallScreen;

  const _DocumentCard({
    required this.name,
    required this.date,
    required this.icon,
    required this.isExpiring,
    required this.isExpired,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isExpired ? AppColors.error : isExpiring ? AppColors.warning : AppColors.success;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: statusColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          date != null ? dateFormat.format(date!) : 'Not set',
          style: TextStyle(color: isExpired ? AppColors.error : isExpiring ? AppColors.warning : AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isExpired ? 'EXPIRED' : isExpiring ? 'EXPIRING SOON' : 'VALID',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
      ),
    );
  }
}
