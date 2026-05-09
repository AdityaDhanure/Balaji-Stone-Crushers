import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/diesel_provider.dart';
import '../../utils/diesel_date_utils.dart';

class AddDieselBottomSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onAddPurchase;
  final Function(Map<String, dynamic>) onAddConsumption;

  const AddDieselBottomSheet({super.key, required this.onAddPurchase, required this.onAddConsumption});

  static void show(BuildContext ctx, {
    required Function(Map<String, dynamic>) onAddPurchase,
    required Function(Map<String, dynamic>) onAddConsumption,
  }) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => AddDieselBottomSheet(onAddPurchase: onAddPurchase, onAddConsumption: onAddConsumption),
    );
  }

  @override
  ConsumerState<AddDieselBottomSheet> createState() => _AddDieselBottomSheetState();
}

class _AddDieselBottomSheetState extends ConsumerState<AddDieselBottomSheet> with SingleTickerProviderStateMixin {
  TabController? _tab;
  final _pumpCtrl = TextEditingController();
  final _purchaseQtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _consumptionQtyCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  int? _vehicleId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab?.dispose();
    for (final c in [_pumpCtrl, _purchaseQtyCtrl, _rateCtrl, _consumptionQtyCtrl, _purposeCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(dieselProvider).vehicles;
    final pad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.only(bottom: pad),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            const Text('Add Diesel Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: TabBar(
              controller: _tab!,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              indicator: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(height: 38, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_gas_station_rounded, size: 14), SizedBox(width: 6), Text('Purchase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
                Tab(height: 38, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.speed_rounded, size: 14), SizedBox(width: 6), Text('Consumption', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(controller: _tab!, children: [
            _buildPurchaseForm(),
            _buildConsumptionForm(vehicles),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPurchaseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionCard(title: 'Pump Details', icon: Icons.local_gas_station_rounded, children: [
          _field(_pumpCtrl, 'Pump Name *', icon: Icons.storefront_rounded),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_purchaseQtyCtrl, 'Quantity (L) *', suffix: 'L', type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_rateCtrl, 'Rate/L', prefix: '₹', type: TextInputType.number)),
          ]),
        ]),
        const SizedBox(height: 12),
        // Live total preview
        ValueListenableBuilder(valueListenable: _purchaseQtyCtrl, builder: (_, __, ___) {
          return ValueListenableBuilder(valueListenable: _rateCtrl, builder: (_, __, ___) {
            final qty = double.tryParse(_purchaseQtyCtrl.text) ?? 0;
            final rate = double.tryParse(_rateCtrl.text) ?? 0;
            final total = qty * rate;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Total Amount', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                Text(total > 0 ? '₹${NumberFormat('#,##,###').format(total)}' : '—', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
              ]),
            );
          });
        }),
        const SizedBox(height: 20),
        _SubmitButton(label: 'Add Purchase', icon: Icons.local_gas_station_rounded, onPressed: _submitPurchase),
      ]),
    );
  }

  Widget _buildConsumptionForm(List<VehicleSimple> vehicles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: StatefulBuilder(builder: (ctx, setSt) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionCard(title: 'Vehicle & Quantity', icon: Icons.local_shipping_rounded, children: [
          DropdownButtonFormField<int>(
            initialValue: _vehicleId,
            decoration: _dec('Select Vehicle *', icon: Icons.directions_car_rounded),
            items: vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.vehicleNumber} (${v.vehicleType})'))).toList(),
            onChanged: (v) => setSt(() => _vehicleId = v),
          ),
          const SizedBox(height: 12),
          _field(_consumptionQtyCtrl, 'Quantity (L) *', suffix: 'L', type: TextInputType.number),
        ]),
        const SizedBox(height: 12),
        _SectionCard(title: 'Purpose', icon: Icons.notes_rounded, children: [
          _field(_purposeCtrl, 'e.g. Transport, Loader work'),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.info),
            const SizedBox(width: 8),
            const Text('Consumption Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(DateFormat('dd MMM yyyy').format(dieselTodayIstDate()), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.info)),
          ]),
        ),
        const SizedBox(height: 20),
        _SubmitButton(label: 'Add Consumption', icon: Icons.speed_rounded, onPressed: _submitConsumption),
      ])),
    );
  }

  void _submitPurchase() {
    if (_pumpCtrl.text.trim().isEmpty || _purchaseQtyCtrl.text.trim().isEmpty) {
      _snack('Enter pump name and quantity'); return;
    }
    final qty = double.tryParse(_purchaseQtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    widget.onAddPurchase({'pump_name': _pumpCtrl.text.trim(), 'quantity': qty, 'rate_per_liter': rate, 'total_amount': qty * rate, 'purchase_date': dieselDateParam(dieselTodayIstDate())});
  }

  void _submitConsumption() {
    if (_vehicleId == null || _consumptionQtyCtrl.text.trim().isEmpty) {
      _snack('Select vehicle and enter quantity'); return;
    }
    widget.onAddConsumption({'vehicle_id': _vehicleId, 'quantity': double.tryParse(_consumptionQtyCtrl.text) ?? 0, 'purpose': _purposeCtrl.text.trim(), 'consumption_date': dieselDateParam(dieselTodayIstDate())});
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  InputDecoration _dec(String l, {String? prefix, String? suffix, IconData? icon}) => InputDecoration(labelText: l, prefixText: prefix, suffixText: suffix, prefixIcon: icon != null ? Icon(icon, size: 18) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12));
  Widget _field(TextEditingController ctrl, String label, {String? prefix, String? suffix, TextInputType? type, IconData? icon}) => TextField(controller: ctrl, keyboardType: type, decoration: _dec(label, prefix: prefix, suffix: suffix, icon: icon));
}

// ─── Edit Consumption Sheet ───────────────────────────────────────────────────

class EditConsumptionSheet extends StatefulWidget {
  final DieselConsumption consumption;
  final Function(Map<String, dynamic>) onUpdate;

  const EditConsumptionSheet({super.key, required this.consumption, required this.onUpdate});

  static void show(BuildContext ctx, {required DieselConsumption consumption, required Function(Map<String, dynamic>) onUpdate}) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => EditConsumptionSheet(consumption: consumption, onUpdate: onUpdate));
  }

  @override
  State<EditConsumptionSheet> createState() => _EditConsumptionSheetState();
}

class _EditConsumptionSheetState extends State<EditConsumptionSheet> {
  late final TextEditingController _qtyCtrl, _purposeCtrl;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.consumption.quantity.toStringAsFixed(1));
    _purposeCtrl = TextEditingController(text: widget.consumption.purpose ?? '');
    _selectedDate = dieselTodayIstDate();
    if (widget.consumption.consumptionDate.isNotEmpty) {
      _selectedDate = dieselParseDate(widget.consumption.consumptionDate);
    }
  }

  @override
  void dispose() { _qtyCtrl.dispose(); _purposeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: pad),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: AppColors.warning, size: 18)),
            const SizedBox(width: 12),
            const Text('Edit Consumption', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
          ]),
        ),
        StatefulBuilder(builder: (ctx, setSt) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SectionCard(title: 'Details', icon: Icons.speed_rounded, children: [
              TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: _dec('Quantity (L) *', suffix: 'L')),
              const SizedBox(height: 12),
              TextField(controller: _purposeCtrl, decoration: _dec('Purpose')),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: dieselTodayIstDate().add(const Duration(days: 1)));
                  if (d != null) setSt(() => _selectedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.textSecondary),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _SubmitButton(
              label: 'Update Consumption',
              icon: Icons.save_rounded,
              color: AppColors.warning,
              onPressed: () {
                final qty = double.tryParse(_qtyCtrl.text) ?? 0;
                if (qty <= 0) { _snack(ctx, 'Enter valid quantity'); return; }
                widget.onUpdate({'quantity': qty, 'purpose': _purposeCtrl.text.trim(), 'consumption_date': dieselDateParam(_selectedDate)});
              },
            ),
          ]),
        )),
      ]),
    );
  }

  void _snack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  InputDecoration _dec(String l, {String? suffix}) => InputDecoration(labelText: l, suffixText: suffix, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12));
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  const _SubmitButton({required this.label, required this.icon, required this.onPressed, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
}
