import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/product_provider.dart';

// ─── Add Sheet ────────────────────────────────────────────────────────────────

class AddProductBottomSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onAddProduct;
  final Function(Map<String, dynamic>) onAddProduction;

  const AddProductBottomSheet({super.key, required this.onAddProduct, required this.onAddProduction});

  static void show(BuildContext ctx, {
    required Function(Map<String, dynamic>) onAddProduct,
    required Function(Map<String, dynamic>) onAddProduction,
  }) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductBottomSheet(onAddProduct: onAddProduct, onAddProduction: onAddProduction),
    );
  }

  @override
  ConsumerState<AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends ConsumerState<AddProductBottomSheet> with SingleTickerProviderStateMixin {
  TabController? _tab;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _prodRateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _royaltyCtrl = TextEditingController();
  final _transportCtrl = TextEditingController();
  int? _catId;
  int? _productId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    Future.microtask(() async {
      await ref.read(productProvider.notifier).loadCategories();
      await ref.read(productProvider.notifier).loadProducts();
      final code = await ref.read(productProvider.notifier).getNextProductCode();
      if (mounted) setState(() => _codeCtrl.text = code);
    });
  }

  @override
  void dispose() {
    _tab?.dispose();
    for (final c in [_nameCtrl, _codeCtrl, _sizeCtrl, _rateCtrl, _prodRateCtrl, _descCtrl, _qtyCtrl, _royaltyCtrl, _transportCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final pad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: pad),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              const Text('Add Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 8),
          // Tab bar
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
                  Tab(height: 38, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_rounded, size: 14), SizedBox(width: 6), Text('New Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
                  Tab(height: 38, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.analytics_rounded, size: 14), SizedBox(width: 6), Text('Production', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(controller: _tab!, children: [
              _buildProductForm(state.categories),
              _buildProductionForm(state.products),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm(List<ProductCategory> cats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionCard(title: 'Basic Info', icon: Icons.info_outline_rounded, children: [
          _field(_codeCtrl, 'Product Code', icon: Icons.qr_code_rounded),
          const SizedBox(height: 12),
          _field(_nameCtrl, 'Product Name *', icon: Icons.label_rounded),
          const SizedBox(height: 12),
          if (cats.isNotEmpty) DropdownButtonFormField<int>(
            initialValue: _catId,
            decoration: _dec('Category', icon: Icons.folder_rounded),
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _catId = v),
          ),
        ]),
        const SizedBox(height: 12),
        _SectionCard(title: 'Pricing', icon: Icons.currency_rupee_rounded, children: [
          Row(children: [
            Expanded(child: _field(_sizeCtrl, 'Size (mm)', type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_rateCtrl, 'Sell Rate/brass', prefix: '₹', type: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          _field(_prodRateCtrl, 'Production Rate/brass', prefix: '₹', type: TextInputType.number),
        ]),
        const SizedBox(height: 12),
        _SectionCard(title: 'Description', icon: Icons.notes_rounded, children: [
          _field(_descCtrl, 'Optional notes...', lines: 2),
        ]),
        const SizedBox(height: 20),
        _SubmitButton(
          label: 'Add Product',
          icon: Icons.inventory_2_rounded,
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) { _snack('Enter product name'); return; }
            widget.onAddProduct({
              'product_code': _codeCtrl.text,
              'name': _nameCtrl.text.trim(),
              'category_id': _catId,
              'size_mm': int.tryParse(_sizeCtrl.text),
              'selling_rate_per_brass': double.tryParse(_rateCtrl.text) ?? 0,
              'production_rate_per_brass': double.tryParse(_prodRateCtrl.text) ?? 0,
              'description': _descCtrl.text,
            });
          },
        ),
      ]),
    );
  }

  Widget _buildProductionForm(List<Product> products) {
    final active = products.where((p) => p.isActive).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionCard(title: 'Product & Quantity', icon: Icons.inventory_rounded, children: [
          DropdownButtonFormField<int>(
            initialValue: _productId,
            decoration: _dec('Select Product *', icon: Icons.inventory_2_rounded),
            items: active.map((p) => DropdownMenuItem(value: p.id, child: Text(p.sizeMm != null ? '${p.name} (${p.sizeMm}mm)' : p.name))).toList(),
            onChanged: (v) => setState(() => _productId = v),
          ),
          const SizedBox(height: 12),
          _field(_qtyCtrl, 'Quantity (brass) *', suffix: 'brass', type: TextInputType.number),
        ]),
        const SizedBox(height: 12),
        _SectionCard(title: 'Costs', icon: Icons.payments_rounded, children: [
          Row(children: [
            Expanded(child: _field(_royaltyCtrl, 'Royalty', prefix: '₹', type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_transportCtrl, 'Transport', prefix: '₹', type: TextInputType.number)),
          ]),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Production Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(DateFormat('dd MMM yyyy').format(appTodayIstDate()), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 20),
        _SubmitButton(
          label: 'Add Production',
          icon: Icons.analytics_rounded,
          onPressed: () {
            if (_productId == null || _qtyCtrl.text.trim().isEmpty) { _snack('Select product and enter quantity'); return; }
            widget.onAddProduction({
              'product_id': _productId,
              'quantity_tons': double.tryParse(_qtyCtrl.text) ?? 0,
              'royalty_amount': double.tryParse(_royaltyCtrl.text) ?? 0,
              'transportation_cost': double.tryParse(_transportCtrl.text) ?? 0,
              'production_date': appDateParam(appTodayIstDate()),
            });
          },
        ),
      ]),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  InputDecoration _dec(String label, {String? prefix, String? suffix, IconData? icon}) => InputDecoration(
    labelText: label, prefixText: prefix, suffixText: suffix, prefixIcon: icon != null ? Icon(icon, size: 18) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Widget _field(TextEditingController ctrl, String label, {String? prefix, String? suffix, TextInputType? type, int lines = 1, IconData? icon}) =>
      TextField(controller: ctrl, keyboardType: type, maxLines: lines, decoration: _dec(label, prefix: prefix, suffix: suffix, icon: icon));
}

// ─── Edit Production Sheet ────────────────────────────────────────────────────

class EditProductionDialog extends ConsumerStatefulWidget {
  final ProductionEntry entry;
  final Function(Map<String, dynamic>) onUpdate;

  const EditProductionDialog({super.key, required this.entry, required this.onUpdate});

  @override
  ConsumerState<EditProductionDialog> createState() => _EditProductionDialogState();
}

class _EditProductionDialogState extends ConsumerState<EditProductionDialog> {
  late final TextEditingController _qtyCtrl, _rateCtrl, _royaltyCtrl, _transportCtrl, _notesCtrl;
  int? _productId;

  @override
  void initState() {
    super.initState();
    _productId = widget.entry.productId;
    _qtyCtrl = TextEditingController(text: widget.entry.quantityTons.toString());
    _rateCtrl = TextEditingController(text: widget.entry.productionRatePerBrass.toString());
    _royaltyCtrl = TextEditingController(text: widget.entry.royaltyAmount.toString());
    _transportCtrl = TextEditingController(text: widget.entry.transportationCost.toString());
    _notesCtrl = TextEditingController(text: widget.entry.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_qtyCtrl, _rateCtrl, _royaltyCtrl, _transportCtrl, _notesCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider).products;
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
            const Text('Edit Production', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
          ]),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: StatefulBuilder(
              builder: (ctx, setSt) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionCard(title: 'Product & Quantity', icon: Icons.inventory_rounded, children: [
                  DropdownButtonFormField<int>(
                    initialValue: _productId,
                    decoration: _dec('Product *', icon: Icons.inventory_2_rounded),
                    items: products.where((p) => p.isActive).map((p) => DropdownMenuItem(value: p.id, child: Text(p.sizeMm != null ? '${p.name} (${p.sizeMm}mm)' : p.name))).toList(),
                    onChanged: (v) => setSt(() => _productId = v),
                  ),
                  const SizedBox(height: 12),
                  _f(_qtyCtrl, 'Quantity (brass) *', suffix: 'brass', type: TextInputType.number),
                  const SizedBox(height: 12),
                  _f(_rateCtrl, 'Production Rate/brass', prefix: '₹', type: TextInputType.number),
                ]),
                const SizedBox(height: 12),
                _SectionCard(title: 'Costs', icon: Icons.payments_rounded, children: [
                  Row(children: [
                    Expanded(child: _f(_royaltyCtrl, 'Royalty', prefix: '₹', type: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _f(_transportCtrl, 'Transport', prefix: '₹', type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _f(_notesCtrl, 'Notes', lines: 2),
                ]),
                const SizedBox(height: 20),
                _SubmitButton(
                  label: 'Update Production',
                  icon: Icons.save_rounded,
                  color: AppColors.warning,
                  onPressed: () {
                    if (_productId == null || _qtyCtrl.text.trim().isEmpty) { _snack(ctx, 'Fill required fields'); return; }
                    widget.onUpdate({
                      'product_id': _productId,
                      'quantity_tons': double.tryParse(_qtyCtrl.text) ?? 0,
                      'production_rate_per_brass': double.tryParse(_rateCtrl.text) ?? 0,
                      'royalty_amount': double.tryParse(_royaltyCtrl.text) ?? 0,
                      'transportation_cost': double.tryParse(_transportCtrl.text) ?? 0,
                      'notes': _notesCtrl.text,
                    });
                  },
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  void _snack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  InputDecoration _dec(String l, {String? prefix, String? suffix, IconData? icon}) => InputDecoration(labelText: l, prefixText: prefix, suffixText: suffix, prefixIcon: icon != null ? Icon(icon, size: 18) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12));
  Widget _f(TextEditingController ctrl, String label, {String? prefix, String? suffix, TextInputType? type, int lines = 1}) => TextField(controller: ctrl, keyboardType: type, maxLines: lines, decoration: _dec(label, prefix: prefix, suffix: suffix));
}

// ─── Edit Product Sheet ───────────────────────────────────────────────────────

class EditProductSheet extends ConsumerStatefulWidget {
  final Product product;
  final Function(Map<String, dynamic>) onUpdate;

  const EditProductSheet({super.key, required this.product, required this.onUpdate});

  static void show(BuildContext ctx, {required Product product, required Function(Map<String, dynamic>) onUpdate}) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => EditProductSheet(product: product, onUpdate: onUpdate));
  }

  @override
  ConsumerState<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<EditProductSheet> {
  late final TextEditingController _nameCtrl, _sizeCtrl, _rateCtrl, _prodRateCtrl, _descCtrl;
  int? _catId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _sizeCtrl = TextEditingController(text: widget.product.sizeMm?.toString() ?? '');
    _rateCtrl = TextEditingController(text: widget.product.currentRate.toString());
    _prodRateCtrl = TextEditingController(text: widget.product.productionRate.toString());
    _descCtrl = TextEditingController(text: widget.product.description ?? '');
    _catId = widget.product.categoryId;
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _sizeCtrl, _rateCtrl, _prodRateCtrl, _descCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(productProvider).categories;
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
            const Text('Edit Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
          ]),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: StatefulBuilder(
              builder: (ctx, setSt) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionCard(title: 'Basic Info', icon: Icons.info_outline_rounded, children: [
                  _f(_nameCtrl, 'Product Name *', icon: Icons.label_rounded),
                  const SizedBox(height: 12),
                  if (cats.isNotEmpty) DropdownButtonFormField<int>(
                    initialValue: _catId,
                    decoration: _dec('Category', icon: Icons.folder_rounded),
                    items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setSt(() => _catId = v),
                  ),
                ]),
                const SizedBox(height: 12),
                _SectionCard(title: 'Pricing', icon: Icons.currency_rupee_rounded, children: [
                  Row(children: [
                    Expanded(child: _f(_sizeCtrl, 'Size (mm)', type: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _f(_rateCtrl, 'Sell Rate/brass', prefix: '₹', type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _f(_prodRateCtrl, 'Production Rate/brass', prefix: '₹', type: TextInputType.number),
                ]),
                const SizedBox(height: 12),
                _SectionCard(title: 'Settings', icon: Icons.settings_rounded, children: [
                  _f(_descCtrl, 'Description', lines: 2),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                    child: SwitchListTile(
                      title: const Text('Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: _isActive,
                      activeThumbColor: AppColors.success,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      onChanged: (v) => setSt(() => _isActive = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                _SubmitButton(
                  label: 'Update Product',
                  icon: Icons.save_rounded,
                  color: AppColors.warning,
                  onPressed: () {
                    if (_nameCtrl.text.trim().isEmpty) { _snack(ctx, 'Enter product name'); return; }
                    widget.onUpdate({
                      'name': _nameCtrl.text.trim(),
                      'category_id': _catId,
                      'size_mm': int.tryParse(_sizeCtrl.text),
                      'selling_rate_per_brass': double.tryParse(_rateCtrl.text) ?? 0,
                      'production_rate_per_brass': double.tryParse(_prodRateCtrl.text) ?? 0,
                      'description': _descCtrl.text,
                      'is_active': _isActive,
                    });
                  },
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  void _snack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  InputDecoration _dec(String l, {String? prefix, String? suffix, IconData? icon}) => InputDecoration(labelText: l, prefixText: prefix, suffixText: suffix, prefixIcon: icon != null ? Icon(icon, size: 18) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12));
  Widget _f(TextEditingController ctrl, String label, {String? prefix, String? suffix, TextInputType? type, int lines = 1, IconData? icon}) => TextField(controller: ctrl, keyboardType: type, maxLines: lines, decoration: _dec(label, prefix: prefix, suffix: suffix, icon: icon));
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
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
