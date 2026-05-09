import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/vehicle_detail_header.dart';
import '../widgets/vehicle_usage_tab.dart';
import '../../../../core/utils/parse_utils.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final int vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> with SingleTickerProviderStateMixin {
  TabController? _tab;
  bool _groupUsageByDate = false;
  List<dynamic> _dateGroupedUsage = [];
  List<dynamic> _usageDates = [];
  bool _loadingDateUsage = false;
  int _lastRefresh = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(vehicleProvider.notifier).loadVehicleDetails(widget.vehicleId));
  }

  @override
  void dispose() { _tab?.dispose(); super.dispose(); }

  Future<void> _loadDateGroupedUsage() async {
    setState(() => _loadingDateUsage = true);
    try {
      final usage = await ref.read(vehicleProvider.notifier).getUsageGroupedByDate(widget.vehicleId);
      final dates = await ref.read(vehicleProvider.notifier).getUsageDates(widget.vehicleId);
      if (mounted) setState(() { _dateGroupedUsage = usage; _usageDates = dates; _loadingDateUsage = false; });
    } catch (_) { if (mounted) setState(() => _loadingDateUsage = false); }
  }

  Future<void> _toggleActive(Map<String, dynamic> vehicle) async {
    final currentStatus = vehicle['status']?.toString() ?? 'active';
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    final ok = await ref.read(vehicleProvider.notifier).updateVehicle(widget.vehicleId, {'status': newStatus});
    if (ok && mounted) {
      _snack(newStatus == 'active' ? 'Vehicle marked as Active' : 'Vehicle marked as Inactive', newStatus == 'active' ? AppColors.success : AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refresh = ref.watch(appRefreshProvider);
    final state = ref.watch(vehicleProvider);
    final vehicle = state.selectedVehicle;
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (refresh != _lastRefresh) {
      _lastRefresh = refresh;
      Future.microtask(() => ref.read(vehicleProvider.notifier).loadVehicleDetails(widget.vehicleId));
    }

    if (state.isLoading && vehicle == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: const Color(0xFF1A2E4A), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()), title: const Text('Loading...', style: TextStyle(color: Colors.white))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: const Color(0xFF1A2E4A), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()), title: const Text('Vehicle', style: TextStyle(color: Colors.white))),
        body: const Center(child: Text('Vehicle not found')),
      );
    }

    final stats = vehicle['stats'] is Map<String, dynamic>
      ? vehicle['stats']
      : {};
    final isActive = vehicle['status']?.toString().toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VehicleDetailAppBar(
        vehicleNumber: vehicle['vehicle_number'] ?? '',
        onEdit: () => context.push('/vehicles/edit/${widget.vehicleId}'),
        onBack: () => context.pop(),
      ),
      body: Column(children: [
        VehicleDetailHeader(
          vehicle: vehicle,
          stats: stats,
          isActive: isActive,
          onToggleActive: () => _toggleActive(vehicle),
        ),
        VehicleDetailTabBar(tabController: _tab!),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
            child: TabBarView(controller: _tab!, children: [
              VehicleDocumentsTabPremium(vehicle: vehicle),
              VehicleUsageTab(
                usage: state.usageRecords,
                groupUsageByDate: _groupUsageByDate,
                dateGroupedUsage: _dateGroupedUsage,
                usageDates: _usageDates,
                loadingDateUsage: _loadingDateUsage,
                onLoadDateGroupedUsage: _loadDateGroupedUsage,
                onToggleGroupBy: (v) => setState(() => _groupUsageByDate = v),
                onEditUsage: (u) => _showEditUsageSheet(u),
              ),
              VehicleInfoTabPremium(vehicle: vehicle, stats: stats),
            ]),
          ),
        ),
      ]),
      floatingActionButton: _AddUsageFAB(onPressed: _showAddUsageSheet),
    );
  }

  // ─── Add Usage Sheet ─────────────────────────────────────────────────────────

  void _showAddUsageSheet() {
    final purposeCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _UsageSheet(
        title: 'Add Usage Record',
        purposeCtrl: purposeCtrl,
        locationCtrl: locationCtrl,
        initialDate: appTodayIstDate(),
        icon: Icons.add_location_rounded,
        submitLabel: 'Add Record',
        onSubmit: (purpose, location, date) async {
          if (purpose.isEmpty) { _snack('Enter a purpose', AppColors.error); return; }
          final nav = Navigator.of(ctx);
          final ok = await ref.read(vehicleProvider.notifier).addUsage({
            'vehicle_id': widget.vehicleId,
            'purpose': purpose,
            'location': location,
            'distance': 0,
            'usage_date': appDateParam(date),
          });
          if (!mounted) return;
          if (ok) { nav.pop(); _snack('Usage added', AppColors.success); }
        },
      ),
    );
  }

  // ─── Edit Usage Sheet ─────────────────────────────────────────────────────────

  void _showEditUsageSheet(dynamic usageRecord) {
    final usageId = int.tryParse(usageRecord['id'].toString());
    if (usageId == null) { _snack('Invalid record', AppColors.error); return; }

    DateTime initialDate = appTodayIstDate();
    final dateStr = usageRecord['usage_date']?.toString();
    if (dateStr != null) { initialDate = appParseIstDate(dateStr) ?? initialDate; }

    final purposeCtrl = TextEditingController(text: usageRecord['purpose']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: usageRecord['location']?.toString() ?? '');

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _UsageSheet(
        title: 'Edit Usage Record',
        purposeCtrl: purposeCtrl,
        locationCtrl: locationCtrl,
        initialDate: initialDate,
        icon: Icons.edit_location_rounded,
        submitLabel: 'Update Record',
        isEdit: true,
        onSubmit: (purpose, location, date) async {
          if (purpose.isEmpty) { _snack('Enter a purpose', AppColors.error); return; }
          final nav = Navigator.of(ctx);
          final ok = await ref.read(vehicleProvider.notifier).updateUsage(usageId, {
            'purpose': purpose,
            'location': location,
            'distance': 0,
            'usage_date': appDateParam(date),
          });
          if (!mounted) return;
          if (ok) {
            nav.pop();
            _snack('Usage updated', AppColors.success);
            if (_groupUsageByDate) _loadDateGroupedUsage();
          }
        },
      ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
  ));
}

// ─── Usage Bottom Sheet ────────────────────────────────────────────────────────

class _UsageSheet extends StatefulWidget {
  final String title;
  final TextEditingController purposeCtrl;
  final TextEditingController locationCtrl;
  final DateTime initialDate;
  final IconData icon;
  final String submitLabel;
  final bool isEdit;
  final Function(String purpose, String location, DateTime date) onSubmit;

  const _UsageSheet({required this.title, required this.purposeCtrl, required this.locationCtrl, required this.initialDate, required this.icon, required this.submitLabel, required this.onSubmit, this.isEdit = false});

  @override
  State<_UsageSheet> createState() => _UsageSheetState();
}

class _UsageSheetState extends State<_UsageSheet> {
  late DateTime _date;

  @override
  void initState() { super.initState(); _date = widget.initialDate; }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    final accent = widget.isEdit ? AppColors.warning : AppColors.primary;

    return Container(
      padding: EdgeInsets.only(bottom: pad),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.icon, color: accent, size: 18)),
            const SizedBox(width: 12),
            Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
          ]),
        ),
        StatefulBuilder(builder: (ctx, setSt) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SectionCard(title: 'Usage Details', icon: Icons.route_rounded, accentColor: accent, children: [
              _field(widget.purposeCtrl, 'Purpose *', icon: Icons.task_alt_rounded),
              const SizedBox(height: 12),
              _field(widget.locationCtrl, 'Location', icon: Icons.location_on_rounded),
            ]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: _date, firstDate: DateTime(2020), lastDate: appTodayIstDate().add(const Duration(days: 1)));
                if (d != null) setSt(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: accent),
                  const SizedBox(width: 10),
                  const Text('Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(DateFormat('dd MMM yyyy').format(_date), style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_calendar_rounded, size: 15, color: accent.withValues(alpha: 0.6)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _SubmitButton(label: widget.submitLabel, icon: widget.isEdit ? Icons.save_rounded : Icons.add_rounded, color: accent, onPressed: () => widget.onSubmit(widget.purposeCtrl.text.trim(), widget.locationCtrl.text.trim(), _date)),
          ]),
        )),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {IconData? icon}) => TextField(
    controller: ctrl,
    decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, size: 18) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.accentColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ])),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _SubmitButton({required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
          child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(12),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  ])))),
    ),
  );
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _AddUsageFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddUsageFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(16),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Add Usage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ])))),
  );
}
