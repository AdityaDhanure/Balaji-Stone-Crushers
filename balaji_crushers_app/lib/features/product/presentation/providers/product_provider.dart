import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductState {
  final bool isLoading;
  final List<Product> products;
  final List<ProductCategory> categories;
  final List<ProductionEntry> production;
  final ProductionSummary? dailySummary;
  final String? error;

  const ProductState({
    this.isLoading = false,
    this.products = const [],
    this.categories = const [],
    this.production = const [],
    this.dailySummary,
    this.error,
  });

  ProductState copyWith({
    bool? isLoading,
    List<Product>? products,
    List<ProductCategory>? categories,
    List<ProductionEntry>? production,
    ProductionSummary? dailySummary,
    String? error,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      production: production ?? this.production,
      dailySummary: dailySummary ?? this.dailySummary,
      error: error,
    );
  }
}

class Product {
  final int id;
  final String productCode;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final int? sizeMm;
  final String? description;
  final double currentRate;
  final double productionRate;
  final bool isActive;

  const Product({
    required this.id,
    required this.productCode,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.sizeMm,
    this.description,
    this.currentRate = 0,
    this.productionRate = 0,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    bool isActive = true;
    
    final isActiveValue = json['is_active'] ?? json['isactive'] ?? json['isActive'] ?? json['active'] ?? json['status'];
    
    if (isActiveValue == null) {
      isActive = true;
    } else if (isActiveValue is bool) {
      isActive = isActiveValue;
    } else if (isActiveValue is num) {
      isActive = isActiveValue != 0;
    } else if (isActiveValue is String) {
      final lower = isActiveValue.toLowerCase();
      isActive = lower == 'true' || isActiveValue == '1' || lower == 'active' || lower == 't' || lower == 'yes' || lower == 'y';
    }
    
    return Product(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productCode: json['product_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',

      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString(),

      sizeMm: int.tryParse(json['size_mm']?.toString() ?? ''),

      description: json['description']?.toString(),

      currentRate: double.tryParse(json['current_rate']?.toString() ?? '0') ?? 0,
      productionRate: double.tryParse(json['current_production_rate']?.toString() ?? '0') ?? 0,

      isActive: isActive,
    );
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String? description;
  final int productCount;

  const ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.productCount = 0,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      productCount: int.tryParse(json['product_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProductionEntry {
  final int id;
  final String productionDate;
  final int productId;
  final String productName;
  final String productCode;
  final int? sizeMm;
  final double quantityTons;
  final double royaltyAmount;
  final double transportationCost;
  final double ratePerTon;
  final double productionRatePerBrass;
  final double totalValue;
  final String? notes;

  const ProductionEntry({
    required this.id,
    required this.productionDate,
    required this.productId,
    required this.productName,
    required this.productCode,
    this.sizeMm,
    required this.quantityTons,
    this.royaltyAmount = 0,
    this.transportationCost = 0,
    this.ratePerTon = 0,
    this.productionRatePerBrass = 0,
    this.totalValue = 0,
    this.notes,
  });

  factory ProductionEntry.fromJson(Map<String, dynamic> json) {
    return ProductionEntry(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      productionDate: json['production_date']?.toString() ?? '',

      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,

      productName: json['product_name']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? '',

      sizeMm: int.tryParse(json['size_mm']?.toString() ?? ''),

      quantityTons: double.tryParse(json['quantity_tons']?.toString() ?? '0') ?? 0,

      royaltyAmount: double.tryParse(json['royalty_amount']?.toString() ?? '0') ?? 0,
      transportationCost: double.tryParse(json['transportation_cost']?.toString() ?? '0') ?? 0,
      ratePerTon: double.tryParse(json['rate_per_brass']?.toString() ?? '0') ?? 0,
      productionRatePerBrass: double.tryParse(json['production_rate_per_brass']?.toString() ?? '0') ?? 0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0,

      notes: json['notes']?.toString(),
    );
  }
}

class ProductionSummary {
  final int entryCount;
  final double totalTons;
  final double totalRoyalty;
  final double totalTransport;
  final double totalValue;

  const ProductionSummary({
    this.entryCount = 0,
    this.totalTons = 0,
    this.totalRoyalty = 0,
    this.totalTransport = 0,
    this.totalValue = 0,
  });

  factory ProductionSummary.fromJson(Map<String, dynamic> json) {
    return ProductionSummary(
      entryCount: int.tryParse(json['entry_count']?.toString() ?? '0') ?? 0,
      totalTons: double.tryParse(json['total_tons']?.toString() ?? '0') ?? 0,
      totalRoyalty: double.tryParse(json['total_royalty']?.toString() ?? '0') ?? 0,
      totalTransport: double.tryParse(json['total_transport']?.toString() ?? '0') ?? 0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repository;

  ProductNotifier(this._repository) : super(const ProductState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getProducts();
      final products = data.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
      state = state.copyWith(products: products);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadCategories() async {
    try {
      final data = await _repository.getCategories();
      final categories = data.map((c) => ProductCategory.fromJson(c as Map<String, dynamic>)).toList();
      state = state.copyWith(categories: categories);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createProduct(data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateProduct(id, data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repository.deleteProduct(id);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> getNextProductCode() async {
    try {
      return await _repository.getNextProductCode();
    } catch (e) {
      return 'PRD-0001';
    }
  }

  Future<void> loadProduction({String? startDate, String? endDate, int? productId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getProduction(
        startDate: startDate,
        endDate: endDate,
        productId: productId,
      );
      final production = data.map((p) => ProductionEntry.fromJson(p as Map<String, dynamic>)).toList();
      production.sort((a, b) => b.productionDate.compareTo(a.productionDate));
      state = state.copyWith(production: production);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadDailySummary(String date) async {
    try {
      final data = await _repository.getDailySummary(date);
      state = state.copyWith(dailySummary: ProductionSummary.fromJson(data));
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createProduction(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createProduction(data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateProduction(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateProduction(id, data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteProduction(int id) async {
    try {
      await _repository.deleteProduction(id);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await loadProducts();
      await loadCategories();
      await loadProduction();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<Map<String, dynamic>>> getProductionGroupedByDate() async {
    try {
      final data = await _repository.getProductionGroupedByDate();
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final notifier = ProductNotifier(ref.read(productRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (_, __) {
    notifier.loadAllData();
  });
  return notifier;
});
