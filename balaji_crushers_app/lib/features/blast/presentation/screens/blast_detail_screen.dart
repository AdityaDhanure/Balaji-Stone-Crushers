import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/blast_provider.dart';
import '../widgets/blast_detail_header.dart';
import '../widgets/blast_detail_trips_tab.dart';
import '../widgets/blast_detail_expenses_tab.dart';
import '../widgets/blast_detail_info_tab.dart';

const _kAccent = Color(0xFFE67E22);
const _kAccentDark = Color(0xFFD35400);

class BlastDetailScreen extends ConsumerStatefulWidget {
  final int blastId;
  const BlastDetailScreen({super.key, required this.blastId});

  @override
  ConsumerState<BlastDetailScreen> createState() => _BlastDetailScreenState();
}

class _BlastDetailScreenState extends ConsumerState<BlastDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Trips state
  bool _groupByVehicle = true;
  List<dynamic> _dateGroupedTrips = [];
  List<dynamic> _tripDates = [];
  bool _loadingDateTrips = false;

  // Expenses state
  bool _groupExpensesByDate = false;
  List<dynamic> _dateGroupedExpenses = [];
  List<dynamic> _expenseDates = [];
  bool _loadingDateExpenses = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(blastProvider.notifier).loadBlastDetails(widget.blastId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blastProvider);
    final blast = state.selectedBlast;
    if (blast == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (blast == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isActive = blast['status'] == 'active';
    final trips = List<dynamic>.from(blast['trips'] ?? []);
    final expenses = List<dynamic>.from(blast['expenses'] ?? []);

    // Always calculate live from arrays for accuracy
    final totalTrips = trips.fold<int>(0, (sum, t) => sum + (int.tryParse(t['trips_count']?.toString() ?? '0') ?? 0));
    final totalExpenses = expenses.fold<double>(0.0, (sum, e) => sum + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: false,
      appBar: BlastDetailAppBar(
        blastNumber: int.tryParse(blast['blast_number']?.toString() ?? '0') ?? 0,
        isActive: isActive,
        onEdit: () => context.push('/blast/edit/${widget.blastId}'),
        onComplete: () => _showStatusDialog(true),
        onReopen: () => _showStatusDialog(false),
        onBack: () { ref.read(blastProvider.notifier).clearSelectedBlast(); context.pop(); },
      ),
      body: Column(children: [
        // Gradient header card
        BlastDetailHeader(blast: blast, isActive: isActive, totalTrips: totalTrips, totalExpenses: totalExpenses, isSmallScreen: isSmall),
        // Tab bar
        BlastDetailTabBar(tabController: _tabController),
        const SizedBox(height: 4),
        // Tab content
        Expanded(child: TabBarView(controller: _tabController, children: [
          TripsTab(
            trips: trips,
            isSmallScreen: isSmall,
            groupByVehicle: _groupByVehicle,
            dateGroupedTrips: _dateGroupedTrips,
            tripDates: _tripDates,
            loadingDateTrips: _loadingDateTrips,
            onLoadDateGroupedTrips: _loadDateGroupedTrips,
            onToggleGroupBy: _handleToggleTripsGroupBy,
            onEditTrip: (trip, firstTripId) => _showEditTripDialog(trip, firstTripId),
          ),
          ExpensesTab(
            expenses: expenses,
            totalExpenses: totalExpenses,
            isSmallScreen: isSmall,
            groupByDate: _groupExpensesByDate,
            dateGroupedExpenses: _dateGroupedExpenses,
            expenseDates: _expenseDates,
            loadingDateExpenses: _loadingDateExpenses,
            onLoadDateGroupedExpenses: _loadDateGroupedExpenses,
            onToggleGroupBy: _handleToggleExpensesGroupBy,
            onEditExpense: (expense) => _showEditExpenseDialog(expense),
          ),
          BlastInfoTab(blast: blast, isSmallScreen: isSmall),
        ])),
      ]),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_kAccent, _kAccentDark]),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Material(
      color: Colors.transparent, borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _showAddBottomSheet, borderRadius: BorderRadius.circular(16),
        child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ])),
      ),
    ),
  );

  // ─── Status Toggle ──────────────────────────────────────────────────────────
  void _showStatusDialog(bool completing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(completing ? Icons.check_circle_rounded : Icons.refresh_rounded,
              color: completing ? AppColors.success : AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Text(completing ? 'Complete Blast' : 'Reopen Blast'),
        ]),
        content: Text(completing ? 'Mark this blast as completed?' : 'Mark this blast as active again?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: completing ? AppColors.success : AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (completing) {
                await ref.read(blastProvider.notifier).completeBlast(widget.blastId);
              } else {
                await ref.read(blastProvider.notifier).reopenBlast(widget.blastId);
              }
            },
            child: Text(completing ? 'Complete' : 'Reopen', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Grouping ───────────────────────────────────────────────────────────────
  void _handleToggleTripsGroupBy(String value) {
    setState(() => _groupByVehicle = value == 'vehicle');
    if (value == 'date') _loadDateGroupedTrips();
  }

  void _handleToggleExpensesGroupBy(String value) {
    setState(() => _groupExpensesByDate = value == 'date');
    if (value == 'date') _loadDateGroupedExpenses();
  }

  Future<void> _loadDateGroupedTrips() async {
    setState(() => _loadingDateTrips = true);
    final trips = await ref.read(blastProvider.notifier).getTripsGroupedByDate(widget.blastId);
    final dates = await ref.read(blastProvider.notifier).getTripDates(widget.blastId);
    if (mounted) setState(() { _dateGroupedTrips = trips; _tripDates = dates; _loadingDateTrips = false; });
  }

  Future<void> _loadDateGroupedExpenses() async {
    setState(() => _loadingDateExpenses = true);
    final expenses = await ref.read(blastProvider.notifier).getExpensesGroupedByDate(widget.blastId);
    final dates = await ref.read(blastProvider.notifier).getExpenseDates(widget.blastId);
    if (mounted) setState(() { _dateGroupedExpenses = expenses; _expenseDates = dates; _loadingDateExpenses = false; });
  }

  // ─── Edit Trip Dialog ───────────────────────────────────────────────────────
  void _showEditTripDialog(dynamic trip, int? firstTripId) {
    if (firstTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find trip ID to edit'), behavior: SnackBarBehavior.floating));
      return;
    }
    final ctrl = TextEditingController(text: trip['trips_count']?.toString() ?? '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.local_shipping_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Edit Trip — ${trip['vehicle_number'] ?? ''}', style: const TextStyle(fontSize: 15))),
        ]),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Number of Trips', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final newCount = int.tryParse(ctrl.text);
              if (newCount == null || newCount < 0) return;
              Navigator.pop(ctx);
              await ref.read(blastProvider.notifier).updateTrip(firstTripId, {'trips_count': newCount, 'blast_id': widget.blastId});
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Edit Expense Dialog ────────────────────────────────────────────────────
  void _showEditExpenseDialog(dynamic expense) {
    final expenseId = int.tryParse(expense['id']?.toString() ?? '');
    if (expenseId == null) return;
    final amountCtrl = TextEditingController(text: expense['amount']?.toString() ?? '');
    final descCtrl = TextEditingController(text: expense['description']?.toString() ?? '');
    String selectedType = expense['expense_type']?.toString() ?? 'other';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.receipt_long_rounded, color: _kAccent, size: 18), SizedBox(width: 8), Text('Edit Expense', style: TextStyle(fontSize: 15))]),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: InputDecoration(labelText: 'Expense Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: ['labour','material','machinery','transport','loading','drilling','other']
                .map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
            onChanged: (v) { if (v != null) setS(() => selectedType = v); },
          ),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount < 0) return;
              Navigator.pop(ctx);
              await ref.read(blastProvider.notifier).updateExpense(expenseId, {'expense_type': selectedType, 'description': descCtrl.text, 'amount': amount, 'blast_id': widget.blastId});
              if (_groupExpensesByDate) await _loadDateGroupedExpenses();
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  // ─── Add Bottom Sheet ───────────────────────────────────────────────────────
  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(blastId: widget.blastId, onAddTrip: _onAddTrip, onAddExpense: _onAddExpense),
    );
  }

  Future<void> _onAddTrip(Map<String, dynamic> data) async {
    await ref.read(blastProvider.notifier).addTrip(data);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _onAddExpense(Map<String, dynamic> data) async {
    await ref.read(blastProvider.notifier).addExpense(data);
    if (mounted) Navigator.pop(context);
  }
}

// ─── Add Entry Bottom Sheet ────────────────────────────────────────────────────
class _AddSheet extends ConsumerStatefulWidget {
  final int blastId;
  final Future<void> Function(Map<String, dynamic>) onAddTrip;
  final Future<void> Function(Map<String, dynamic>) onAddExpense;
  const _AddSheet({required this.blastId, required this.onAddTrip, required this.onAddExpense});
  @override
  ConsumerState<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _vehicleType;
  String? _vehicleNumber;
  int? _vehicleId;
  List<String> _vehicleTypes = [];
  List<dynamic> _vehicles = [];
  bool _loadingVehicles = false;
  final _tripsCtrl = TextEditingController(text: '1');
  String _expenseType = 'labour';
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    final types = await ref.read(blastProvider.notifier).getVehicleTypes();
    if (mounted) setState(() => _vehicleTypes = types);
  }

  Future<void> _loadVehiclesByType(String type) async {
    setState(() { _loadingVehicles = true; _vehicleNumber = null; _vehicleId = null; });
    final vehicles = await ref.read(blastProvider.notifier).getVehiclesByType(type);
    if (mounted) setState(() { _vehicles = vehicles; _loadingVehicles = false; });
  }

  @override
  void dispose() { _tab.dispose(); _tripsCtrl.dispose(); _amountCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Text('Add Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: TabBar(
            controller: _tab,
            labelColor: _kAccent,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(color: _kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            tabs: const [Tab(text: 'Add Trip'), Tab(text: 'Add Expense')],
          ),
        ),
        SizedBox(
          height: 280,
          child: TabBarView(controller: _tab, children: [_buildTripForm(), _buildExpenseForm()]),
        ),
      ]),
    );
  }

  Widget _buildTripForm() => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 14),
    child: Column(children: [
      DropdownButtonFormField<String>(
        initialValue: _vehicleType,
        decoration: InputDecoration(labelText: 'Vehicle Type *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) { setState(() => _vehicleType = v); if (v != null) _loadVehiclesByType(v); },
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _vehicleNumber,
        decoration: InputDecoration(labelText: 'Vehicle Number *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: _vehicles.map((v) => DropdownMenuItem(value: v['vehicle_number'].toString(), child: Text(v['vehicle_number'].toString()))).toList(),
        onChanged: (v) {
          final vehicle = _vehicles.firstWhere((x) => x['vehicle_number'].toString() == v, orElse: () => <String, dynamic>{});
          setState(() { _vehicleNumber = v; _vehicleId = vehicle['id']; });
        },
      ),
      if (_loadingVehicles) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)),
      const SizedBox(height: 10),
      TextField(controller: _tripsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Number of Trips', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      const SizedBox(height: 14),
      _ActionBtn(label: 'Add Trip', onTap: () {
        if (_vehicleNumber == null) return;
        widget.onAddTrip({'blast_id': widget.blastId, 'vehicle_id': _vehicleId, 'vehicle_number': _vehicleNumber, 'vehicle_type': _vehicleType, 'trips_count': int.tryParse(_tripsCtrl.text) ?? 1, 'trip_date': appDateParam(appTodayIstDate())});
      }),
    ]),
  );

  Widget _buildExpenseForm() => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 14),
    child: Column(children: [
      DropdownButtonFormField<String>(
        initialValue: _expenseType,
        decoration: InputDecoration(labelText: 'Expense Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: ['labour','material','machinery','transport','loading','drilling','other']
            .map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
        onChanged: (v) => setState(() => _expenseType = v!),
      ),
      const SizedBox(height: 10),
      TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      const SizedBox(height: 10),
      TextField(controller: _descCtrl, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      const SizedBox(height: 14),
      _ActionBtn(label: 'Add Expense', onTap: () {
        if (_amountCtrl.text.isEmpty) return;
        widget.onAddExpense({'blast_id': widget.blastId, 'expense_type': _expenseType, 'amount': double.tryParse(_amountCtrl.text) ?? 0, 'description': _descCtrl.text, 'expense_date': appDateParam(appTodayIstDate())});
      }),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kAccent, _kAccentDark]), borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)))))),
    ),
  );
}
