import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/session_ui_state_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/widgets.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _groupByDate = false;
  List<Map<String, dynamic>> _grouped = [];
  bool _loadingGrouped = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(sessionTabIndexProvider('crusher')).clamp(0, 2).toInt();
    _tab = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tab.addListener(() {
      ref.read(sessionTabIndexProvider('crusher').notifier).state = _tab.index;
    });
    Future.microtask(() => ref.read(productProvider.notifier).loadAllData());
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadGrouped() async {
    setState(() => _loadingGrouped = true);
    try {
      final data = await ref.read(productProvider.notifier).getProductionGroupedByDate();
      if (mounted) setState(() { _grouped = data; _loadingGrouped = false; });
    } catch (_) { if (mounted) setState(() => _loadingGrouped = false); }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          Padding(
            padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, isSmall ? 12 : 20, isSmall ? 12 : 20, 0),
            child: ProductStatsCard(
              totalProducts: state.products.length,
              activeProducts: state.products.where((p) => p.isActive).length,
              categoriesCount: state.categories.length,
              productionEntries: state.production.length,
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar (billing style)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: [
                  _buildTab('Products', Icons.inventory_2_rounded, state.products.length),
                  _buildTab('Production', Icons.analytics_rounded, state.production.length),
                  _buildTab('Categories', Icons.folder_rounded, state.categories.length),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Tab content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
              child: TabBarView(controller: _tab, children: [
                ProductsTab(
                  products: state.products,
                  isLoading: state.isLoading,
                  onEdit: _showEditProduct,
                ),
                ProductionTab(
                  production: state.production,
                  isLoading: state.isLoading,
                  groupProductionByDate: _groupByDate,
                  dateGroupedProduction: _grouped,
                  loadingDateGroupedProduction: _loadingGrouped,
                  onLoadDateGroupedProduction: _loadGrouped,
                  onToggleGroupBy: (v) => setState(() => _groupByDate = v),
                  onEdit: _showEditProduction,
                ),
                CategoriesTab(
                  categories: state.categories,
                  isLoading: state.isLoading,
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _FAB(onPressed: _showAdd),
    );
  }

  Tab _buildTab(String label, IconData icon, int count) => Tab(
    height: 44,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13),
      const SizedBox(width: 4),
      Text(label),
      if (count > 0) ...[
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
      ],
    ]),
  );

  void _showAdd() {
    AddProductBottomSheet.show(
      context,
      onAddProduct: (data) async {
        final nav = Navigator.of(context);
        final ok = await ref.read(productProvider.notifier).createProduct(data);
        if (!mounted) return;
        if (ok) { nav.pop(); _snack('Product added', AppColors.success); }
      },
      onAddProduction: (data) async {
        final nav = Navigator.of(context);
        final ok = await ref.read(productProvider.notifier).createProduction(data);
        if (!mounted) return;
        if (ok) {
          if (_groupByDate) await _loadGrouped();
          nav.pop();
          _snack('Production entry added', AppColors.success);
        }
      },
    );
  }

  void _showEditProduct(Product product) {
    EditProductSheet.show(
      context,
      product: product,
      onUpdate: (data) async {
        final ok = await ref.read(productProvider.notifier).updateProduct(product.id, data);
        if (!mounted) return;
        if (ok) {
          final nav = Navigator.of(context);
          await ref.read(productProvider.notifier).loadProducts();
          nav.pop();
          _snack('Product updated', AppColors.success);
        }
      },
    );
  }

  void _showEditProduction(ProductionEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProductionDialog(
        entry: entry,
        onUpdate: (data) async {
          final nav = Navigator.of(ctx);
          final ok = await ref.read(productProvider.notifier).updateProduction(entry.id, data);
          if (!mounted) return;
          if (ok) {
            await ref.read(productProvider.notifier).loadProduction();
            nav.pop();
            _snack('Production updated', AppColors.success);
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

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _FAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _FAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }
}
