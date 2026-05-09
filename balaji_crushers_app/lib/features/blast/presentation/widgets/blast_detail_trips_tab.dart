import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

const _kAccent = Color(0xFFE67E22);

class TripsTab extends StatelessWidget {
  final List<dynamic> trips;
  final bool isSmallScreen;
  final bool groupByVehicle;
  final List<dynamic> dateGroupedTrips;
  final List<dynamic> tripDates;
  final bool loadingDateTrips;
  final Function() onLoadDateGroupedTrips;
  final Function(String) onToggleGroupBy;
  final Function(dynamic, int?) onEditTrip;

  const TripsTab({
    super.key,
    required this.trips,
    required this.isSmallScreen,
    required this.groupByVehicle,
    required this.dateGroupedTrips,
    required this.tripDates,
    required this.loadingDateTrips,
    required this.onLoadDateGroupedTrips,
    required this.onToggleGroupBy,
    required this.onEditTrip,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_shipping_outlined, size: 52, color: AppColors.border),
        SizedBox(height: 14),
        Text('No trips recorded', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('Add a trip using the + button', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]));
    }
    return Column(children: [
      _buildToggle(),
      Expanded(child: groupByVehicle ? _buildVehicleList() : _buildDateList()),
    ]);
  }

  Widget _buildToggle() {
    final count = groupByVehicle ? trips.length : tripDates.length;
    final label = groupByVehicle ? 'vehicles' : 'dates';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        _Chip(label: 'By Vehicle', selected: groupByVehicle, onTap: () => onToggleGroupBy('vehicle')),
        const SizedBox(width: 8),
        _Chip(label: 'By Date', selected: !groupByVehicle, onTap: () {
          if (groupByVehicle) {
            onToggleGroupBy('date');
            onLoadDateGroupedTrips();
          }
        }),
        const Spacer(),
        Text('$count $label', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildVehicleList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
    itemCount: trips.length,
    itemBuilder: (_, i) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _VehicleTripCard(trip: trips[i], onEdit: onEditTrip),
    ),
  );

  Widget _buildDateList() {
    if (loadingDateTrips) return const Center(child: CircularProgressIndicator());
    if (dateGroupedTrips.isEmpty) {
      return const Center(child: Text('No date-wise trips', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      itemCount: dateGroupedTrips.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _DateTripCard(dateGroup: dateGroupedTrips[i], onEdit: onEditTrip),
      ),
    );
  }
}

// ─── Toggle Chip ───────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? _kAccent : AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

// ─── Vehicle Trip Card ─────────────────────────────────────────────────────────
class _VehicleTripCard extends StatelessWidget {
  final dynamic trip;
  final Function(dynamic, int?) onEdit;
  const _VehicleTripCard({required this.trip, required this.onEdit});

  List<int> _parseTripIds(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => int.tryParse(e.toString())).whereType<int>().toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return raw.replaceAll('{', '').replaceAll('}', '').split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final tripCount = int.tryParse(trip['trips_count']?.toString() ?? '0') ?? 0;
    final entriesCount = int.tryParse(trip['entries_count']?.toString() ?? '0') ?? 0;
    final tripIds = _parseTripIds(trip['trip_ids']);
    // Fallback to trip['id'] if trip_ids parsing fails
    final firstId = tripIds.isNotEmpty ? tripIds.first : int.tryParse(trip['id']?.toString() ?? '');
    String lastDate = 'N/A';
    final parsedLastDate = appParseIstDate(trip['last_trip_date']);
    if (parsedLastDate != null) lastDate = DateFormat('dd MMM yyyy').format(parsedLastDate);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
            child: const Icon(Icons.local_shipping_rounded, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip['vehicle_number']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 3),
            Text('${trip['vehicle_type'] ?? 'N/A'} · $lastDate · $entriesCount entries', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$tripCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            const Text('trips', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Date Trip Card ────────────────────────────────────────────────────────────
class _DateTripCard extends StatelessWidget {
  final dynamic dateGroup;
  final Function(dynamic, int?) onEdit;
  const _DateTripCard({required this.dateGroup, required this.onEdit});

  List<dynamic> _parseList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    dt = appParseIstDate(dateGroup['trip_date']);
    final dateLabel = dt != null ? DateFormat('dd MMM yyyy').format(dt) : 'Unknown';
    final totalTrips = dateGroup['total_trips']?.toString() ?? '0';
    final entriesCount = dateGroup['entries_count']?.toString() ?? '0';
    final tripsList = _parseList(dateGroup['trips']);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading: dt != null ? _DateBadge(dt: dt) : const Icon(Icons.calendar_today_rounded, color: _kAccent),
          title: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text('$entriesCount entries · $totalTrips trips', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          children: tripsList.map<Widget>((item) {
            final tripId = int.tryParse(item['id']?.toString() ?? '');
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['vehicle_number']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('${item['vehicle_type'] ?? 'N/A'} · ${item['trips_count']} trips', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ])),
                Material(
                  color: AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: () => onEdit(item, tripId),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.edit_rounded, size: 12, color: AppColors.textSecondary)),
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Date Badge ────────────────────────────────────────────────────────────────
class _DateBadge extends StatelessWidget {
  final DateTime dt;
  const _DateBadge({required this.dt});

  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(
      color: _kAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(DateFormat('dd').format(dt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kAccent)),
      Text(DateFormat('MMM').format(dt), style: const TextStyle(fontSize: 9, color: _kAccent)),
    ]),
  );
}
