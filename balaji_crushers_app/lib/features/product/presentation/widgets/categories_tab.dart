import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/product_provider.dart';

class CategoriesTab extends StatelessWidget {
  final List<ProductCategory> categories;
  final bool isLoading;

  const CategoriesTab({super.key, required this.categories, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (categories.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategoryCard(category: categories[i]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProductCategory category;
  const _CategoryCard({required this.category});

  // Stable color from name hash
  Color _accentColor() {
    final colors = [AppColors.primary, AppColors.success, AppColors.info, const Color(0xFF8E44AD), const Color(0xFFE67E22)];
    return colors[category.name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(width: 3, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.07)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.folder_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  if (category.description != null && category.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(category.description!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_rounded, size: 12, color: color),
                const SizedBox(width: 4),
                Text('${category.productCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(Icons.folder_outlined, size: 44, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('No categories yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Categories are created via the backend', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}