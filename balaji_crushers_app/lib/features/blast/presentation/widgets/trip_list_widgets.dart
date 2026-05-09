import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

class TripListItem extends StatelessWidget {
  final dynamic trip;
  final bool isSmallScreen;
  final DateFormat dateFormat;
  final Function(String) onEdit;
  final Function(List<int>) onDelete;

  const TripListItem({
    super.key,
    required this.trip,
    required this.isSmallScreen,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final entriesCount = int.tryParse(trip['entries_count'].toString()) ?? 0;
    final parsedLastDate = appParseIstDate(trip['last_trip_date']);
    final lastDate = parsedLastDate != null ? dateFormat.format(parsedLastDate) : 'N/A';
    final tripIds = _parseTripIds();

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: ListTile(
        leading: Container(
          width: isSmallScreen ? 40 : 45,
          height: isSmallScreen ? 40 : 45,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_shipping_rounded, color: AppColors.info),
        ),
        title: Text(trip['vehicle_number']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${trip['vehicle_type']?.toString() ?? 'N/A'} • $lastDate • $entriesCount entries',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _buildTrailing(tripIds),
      ),
    );
  }

  List<int> _parseTripIds() {
    final tripIdsRaw = trip['trip_ids'];
    if (tripIdsRaw == null) return [];
    
    if (tripIdsRaw is List) {
      return tripIdsRaw.map((e) => int.tryParse(e.toString())).whereType<int>().toList();
    } else if (tripIdsRaw is String && tripIdsRaw.isNotEmpty) {
      return tripIdsRaw
          .replaceAll('{', '')
          .replaceAll('}', '')
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    }
    return [];
  }

  Widget _buildTrailing(List<int> tripIds) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${trip['trips_count']} trips', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            if (value == 'edit' && tripIds.isNotEmpty) {
              onEdit(tripIds.first.toString());
            } else if (value == 'delete') {
              onDelete(tripIds);
            }
          },
          itemBuilder: (popupContext) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ],
    );
  }
}

class DateGroupedTripItem extends StatelessWidget {
  final dynamic dateGroup;
  final bool isSmallScreen;
  final DateFormat dateFormat;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  const DateGroupedTripItem({
    super.key,
    required this.dateGroup,
    required this.isSmallScreen,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tripDateStr = dateGroup['trip_date']?.toString();
    final totalTrips = int.tryParse(dateGroup['total_trips'].toString()) ?? 0;
    final entriesCount = int.tryParse(dateGroup['entries_count'].toString()) ?? 0;
    final tripDateTime = _parseDate(tripDateStr);
    final formattedDate = tripDateTime != null ? dateFormat.format(tripDateTime) : 'Unknown';
    final tripsList = _parseTripsList();

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: ExpansionTile(
        leading: _buildDateIcon(tripDateTime),
        title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$entriesCount entries • $totalTrips trips', style: const TextStyle(fontSize: 12)),
        children: tripsList.map<Widget>((tripItem) => _buildTripTile(tripItem)).toList(),
      ),
    );
  }

  DateTime? _parseDate(String? dateStr) {
    return appParseIstDate(dateStr);
  }

  Widget _buildDateIcon(DateTime? dateTime) {
    return Container(
      width: isSmallScreen ? 40 : 45,
      height: isSmallScreen ? 40 : 45,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (dateTime != null) ...[
            Text(DateFormat('dd').format(dateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            Text(DateFormat('MMM').format(dateTime), style: const TextStyle(fontSize: 10, color: AppColors.primary)),
          ] else ...[
            const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  List<dynamic> _parseTripsList() {
    final tripsRaw = dateGroup['trips'];
    if (tripsRaw is List) return tripsRaw;
    return [];
  }

  Widget _buildTripTile(dynamic tripItem) {
    final tripId = int.tryParse(tripItem['id'].toString());
    return ListTile(
      dense: true,
      leading: const Icon(Icons.local_shipping_rounded, size: 20, color: AppColors.info),
      title: Text(tripItem['vehicle_number']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 14)),
      subtitle: Text('${tripItem['vehicle_type']?.toString() ?? 'N/A'} • ${tripItem['trips_count']} trips', style: const TextStyle(fontSize: 12)),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) {
          if (value == 'edit' && tripId != null) {
            onEdit(tripItem);
          } else if (value == 'delete' && tripId != null) {
            onDelete(tripId);
          }
        },
        itemBuilder: (popupContext) => [
          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))])),
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red))])),
        ],
      ),
    );
  }
}
