import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

// ─── Detail Header Card (gradient, 3 stats: trips · diesel · odometer) ─────────

class VehicleDetailHeader extends StatelessWidget {
  final dynamic vehicle;
  final Map<String, dynamic> stats;
  final bool isActive;
  final VoidCallback onToggleActive;

  const VehicleDetailHeader({
    super.key,
    required this.vehicle,
    required this.stats,
    required this.isActive,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    final totalTrips = int.tryParse(stats['total_trips']?.toString() ?? '0') ?? 0;
    final totalDiesel = double.tryParse(stats['total_diesel']?.toString() ?? '0') ?? 0;
    final odometer = double.tryParse(vehicle['odometer_reading']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2E4A), Color(0xFF1E4976), Color(0xFF0D3259)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF1E4976).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(top: -25, right: -15, child: _circle(100, 0.08)),
        Positioned(bottom: -35, right: 70, child: _circle(80, 0.05)),
        Padding(
          padding: EdgeInsets.fromLTRB(isSmall ? 14 : 20, 14, isSmall ? 14 : 20, isSmall ? 14 : 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: isSmall ? 46 : 54, height: isSmall ? 46 : 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Icon(_vehicleIcon(vehicle['vehicle_type'] ?? ''), color: Colors.white, size: isSmall ? 24 : 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((vehicle['vehicle_type'] ?? '').toString().toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                if (vehicle['owner_name'] != null && vehicle['owner_name'].toString().isNotEmpty)
                  Text('Owner: ${vehicle['owner_name']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
              ])),
              // Active toggle
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: isActive,
                    onChanged: (_) => onToggleActive(),
                    activeThumbColor: const Color(0xFF2ECC71),
                    activeTrackColor: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? const Color(0xFF2ECC71) : Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _StatChip(label: 'Total Trips', value: '$totalTrips', icon: Icons.route_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Diesel Used', value: '${totalDiesel.toStringAsFixed(1)} L', icon: Icons.local_gas_station_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Odometer', value: '${odometer.toStringAsFixed(0)} km', icon: Icons.speed_rounded)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)));

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'truck': case 'hyva': return Icons.local_shipping_rounded;
      case 'tractor': return Icons.agriculture_rounded;
      case 'jcb': return Icons.construction_rounded;
      case 'loader': return Icons.precision_manufacturing_rounded;
      case 'pockland': return Icons.landscape_rounded;
      case 'roller': return Icons.tire_repair_rounded;
      case 'paver': return Icons.layers_rounded;
      case 'water tanker': return Icons.water_drop_rounded;
      default: return Icons.directions_car_rounded;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
      ])),
    ]),
  );
}

// ─── Premium Boxed Tab Bar ─────────────────────────────────────────────────────

class VehicleDetailTabBar extends StatelessWidget {
  final TabController tabController;
  const VehicleDetailTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    return Container(
      margin: EdgeInsets.fromLTRB(isSmall ? 12 : 20, 12, isSmall ? 12 : 20, 0),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(height: 42, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.description_rounded, size: 13), SizedBox(width: 5), Text('Documents')])),
          Tab(height: 42, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.route_rounded, size: 13), SizedBox(width: 5), Text('Usage')])),
          Tab(height: 42, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.info_outline_rounded, size: 13), SizedBox(width: 5), Text('Info')])),
        ],
      ),
    );
  }
}

// ─── AppBar (no delete, edit only) ────────────────────────────────────────────

class VehicleDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String vehicleNumber;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const VehicleDetailAppBar({super.key, required this.vehicleNumber, required this.onEdit, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1A2E4A),
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: onBack),
      title: Text(vehicleNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
          ),
          onPressed: onEdit,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── Premium Documents Tab ─────────────────────────────────────────────────────

class VehicleDocumentsTabPremium extends StatelessWidget {
  final dynamic vehicle;
  const VehicleDocumentsTabPremium({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    final docs = [
      {'name': 'Insurance', 'date': vehicle['insurance_expiry'], 'icon': Icons.security_rounded},
      {'name': 'PUC Certificate', 'date': vehicle['puc_expiry'], 'icon': Icons.eco_rounded},
      {'name': 'Passing Certificate', 'date': vehicle['passing_expiry'], 'icon': Icons.verified_rounded},
      {'name': 'Road Tax', 'date': vehicle['road_tax_expiry'], 'icon': Icons.receipt_long_rounded},
    ];

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, 12, isSmall ? 12 : 20, 100),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];
        final date = appParseIstDate(doc['date']);
        final daysLeft = date?.difference(appTodayIstDate()).inDays;
        final isExpired = daysLeft != null && daysLeft < 0;
        final isExpiring = daysLeft != null && daysLeft >= 0 && daysLeft <= 30;
        final isValid = !isExpired && !isExpiring;
        final statusColor = isExpired ? AppColors.error : isExpiring ? AppColors.warning : AppColors.success;
        final statusLabel = isExpired ? 'EXPIRED' : isExpiring ? 'EXPIRING IN $daysLeft DAYS' : 'VALID';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isValid ? AppColors.border : statusColor.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 3, height: 46, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(doc['icon'] as IconData, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 3),
                Text(date != null ? DateFormat('dd MMM yyyy').format(date) : 'Not set', style: TextStyle(fontSize: 11, color: isValid ? AppColors.textSecondary : statusColor)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.4)),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Premium Info Tab ──────────────────────────────────────────────────────────

class VehicleInfoTabPremium extends StatelessWidget {
  final dynamic vehicle;
  final Map<String, dynamic> stats;
  const VehicleInfoTabPremium({super.key, required this.vehicle, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, 12, isSmall ? 12 : 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(title: 'Vehicle Info', icon: Icons.directions_car_rounded),
        _InfoCard(rows: [
          _InfoEntry('Vehicle Number', vehicle['vehicle_number'] ?? 'N/A'),
          _InfoEntry('Type', (vehicle['vehicle_type'] ?? '').toString().toUpperCase()),
          _InfoEntry('Owner', vehicle['owner_name'] ?? 'N/A'),
          _InfoEntry('Status', (vehicle['status'] ?? '').toString().toUpperCase()),
        ]),
        const SizedBox(height: 14),
        _SectionHeader(title: 'Financial', icon: Icons.account_balance_wallet_rounded),
        _InfoCard(rows: [
          _InfoEntry('RTO EMI', vehicle['rto_emi_amount'] != null ? '₹${vehicle['rto_emi_amount']}' : 'N/A'),
          _InfoEntry('EMI Due Date', appParseIstDate(vehicle['rto_emi_due_date']) != null ? dateFormat.format(appParseIstDate(vehicle['rto_emi_due_date'])!) : 'N/A'),
        ]),
        const SizedBox(height: 14),
        _SectionHeader(title: 'Stats', icon: Icons.bar_chart_rounded),
        _InfoCard(rows: [
          _InfoEntry('Odometer Reading', '${vehicle['odometer_reading'] ?? 0} km'),
          _InfoEntry('Usage Days', '${stats['usage_days'] ?? 0}'),
        ]),
        if (vehicle['notes'] != null && vehicle['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionHeader(title: 'Notes', icon: Icons.notes_rounded),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Text(vehicle['notes'].toString(), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 13, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final List<_InfoEntry> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(children: rows.asMap().entries.map((e) {
      final isLast = e.key == rows.length - 1;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Text(e.value.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            Text(e.value.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5), indent: 14, endIndent: 14),
      ]);
    }).toList()),
  );
}

class _InfoEntry {
  final String label;
  final String value;
  const _InfoEntry(this.label, this.value);
}
