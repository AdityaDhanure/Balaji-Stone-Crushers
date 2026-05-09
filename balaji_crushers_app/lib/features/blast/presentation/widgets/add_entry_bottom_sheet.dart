import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/blast_provider.dart';

class AddEntryBottomSheet extends ConsumerStatefulWidget {
  final int blastId;
  final Function(Map<String, dynamic>) onAddTrip;
  final Function(Map<String, dynamic>) onAddExpense;

  const AddEntryBottomSheet({
    super.key,
    required this.blastId,
    required this.onAddTrip,
    required this.onAddExpense,
  });

  @override
  ConsumerState<AddEntryBottomSheet> createState() => _AddEntryBottomSheetState();
}

class _AddEntryBottomSheetState extends ConsumerState<AddEntryBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tripsCountController = TextEditingController(text: '1');
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _expenseType = 'labour';
  String? _selectedVehicleType;
  String? _selectedVehicleNumber;
  int? _selectedVehicleId;
  List<String> _vehicleTypes = [];
  List<dynamic> _vehicles = [];
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final types = await ref.read(blastProvider.notifier).getVehicleTypes();
      if (mounted) setState(() => _vehicleTypes = types);
    } catch (e) {
      debugPrint('Error loading vehicle types: $e');
    }
  }

  Future<void> _loadVehiclesByType(String type) async {
    setState(() {
      _isLoadingVehicles = true;
      _selectedVehicleNumber = null;
      _selectedVehicleId = null;
    });
    try {
      final vehicles = await ref.read(blastProvider.notifier).getVehiclesByType(type);
      if (mounted) { setState(() {
        _vehicles = vehicles;
        _isLoadingVehicles = false;
      }); }
    } catch (e) {
      debugPrint('Error loading vehicles by type: $e');
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tripsCountController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Add Entry', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            tabs: const [Tab(text: 'Add Trip'), Tab(text: 'Add Expense')],
          ),
          SizedBox(
            height: isSmallScreen ? 280 : 300,
            child: TabBarView(
              controller: _tabController,
              children: [_buildTripForm(), _buildExpenseForm()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicleType,
            decoration: const InputDecoration(labelText: 'Vehicle Type *', border: OutlineInputBorder()),
            items: _vehicleTypes.map((t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
            onChanged: (value) {
              setState(() => _selectedVehicleType = value);
              if (value != null) _loadVehiclesByType(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicleNumber,
            decoration: const InputDecoration(labelText: 'Vehicle Number *', border: OutlineInputBorder()),
            items: _vehicles.map((v) => DropdownMenuItem<String>(value: v['vehicle_number'].toString(), child: Text(v['vehicle_number'].toString()))).toList(),
            onChanged: (value) {
              final vehicle = _vehicles.firstWhere((v) => v['vehicle_number'].toString() == value, orElse: () => <String, dynamic>{});
              setState(() {
                _selectedVehicleNumber = value;
                _selectedVehicleId = vehicle['id'];
              });
            },
          ),
          if (_isLoadingVehicles) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 12),
          TextField(
            controller: _tripsCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of Trips', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleAddTrip,
              child: const Text('Add Trip'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _expenseType,
            decoration: const InputDecoration(labelText: 'Expense Type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'labour', child: Text('Labour')),
              DropdownMenuItem(value: 'material', child: Text('Material')),
              DropdownMenuItem(value: 'machinery', child: Text('Machinery')),
              DropdownMenuItem(value: 'transport', child: Text('Transport')),
              DropdownMenuItem(value: 'loading', child: Text('Loading/Unloading')),
              DropdownMenuItem(value: 'drilling', child: Text('Drilling')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) => setState(() => _expenseType = value!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleAddExpense,
              child: const Text('Add Expense'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddTrip() {
    if (_selectedVehicleNumber == null || _selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select vehicle type and number')));
      return;
    }
    widget.onAddTrip({
      'blast_id': widget.blastId,
      'vehicle_id': _selectedVehicleId,
      'vehicle_number': _selectedVehicleNumber,
      'vehicle_type': _selectedVehicleType,
      'trips_count': int.tryParse(_tripsCountController.text) ?? 1,
      'trip_date': appDateParam(appTodayIstDate()),
    });
  }

  void _handleAddExpense() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter amount')));
      return;
    }
    widget.onAddExpense({
      'blast_id': widget.blastId,
      'expense_type': _expenseType,
      'amount': double.tryParse(_amountController.text) ?? 0,
      'description': _descriptionController.text,
      'expense_date': appDateParam(appTodayIstDate()),
    });
  }
}
