// Domain models for HomeReminder v0.3.0 (Custom Stores, Favorites, Essentials/Always Buy)

enum ProductCategory {
  cosmetics('cosmetics', 'Косметика', 'Kosmetyki'),
  chemistry('chemistry', 'Бытовая химия', 'Chemia domowa'),
  paper('paper', 'Бумага и салфетки', 'Papier i ręczniki');

  const ProductCategory(this.apiValue, this.labelRu, this.labelPl);
  final String apiValue;
  final String labelRu;
  final String labelPl;

  String label(bool isPl) => isPl ? labelPl : labelRu;

  static ProductCategory fromApi(String val) {
    return ProductCategory.values.firstWhere(
      (e) => e.apiValue == val,
      orElse: () => ProductCategory.cosmetics,
    );
  }
}

enum VolumeUnit {
  ml('ml', 'мл', 'ml'),
  g('g', 'г', 'g'),
  pcs('pcs', 'шт', 'szt.'),
  rolls('rolls', 'рул.', 'rol.'),
  sheets('sheets', 'лист.', 'listków'),
  packs('packs', 'упак.', 'opak.'),
  washes('washes', 'стирок', 'prań');

  const VolumeUnit(this.apiValue, this.labelRu, this.labelPl);
  final String apiValue;
  final String labelRu;
  final String labelPl;

  String label(bool isPl) => isPl ? labelPl : labelRu;

  static VolumeUnit fromApi(String val) {
    return VolumeUnit.values.firstWhere(
      (e) => e.apiValue == val,
      orElse: () => VolumeUnit.ml,
    );
  }
}

class CustomStoreConfig {
  const CustomStoreConfig({
    required this.name,
    required this.searchUrlTemplate,
    this.isBuiltIn = false,
  });

  final String name;
  final String searchUrlTemplate;
  final bool isBuiltIn;

  String buildSearchUrl(String encodedQuery) {
    final tpl = searchUrlTemplate.trim();
    if (tpl.contains('{query}')) {
      return tpl.replaceAll('{query}', encodedQuery);
    }
    // Smart auto-detection for common domains if user only pasted domain URL
    final lower = tpl.toLowerCase();
    var base = tpl.startsWith('http') ? tpl : 'https://$tpl';
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (lower.contains('notino.pl')) {
      return '$base/search.asp?exps=$encodedQuery';
    }
    if (lower.contains('ceneo.pl')) {
      return '$base/;szukaj-$encodedQuery';
    }
    if (lower.contains('superpharm.pl')) {
      return '$base/catalogsearch/result/?q=$encodedQuery';
    }
    if (lower.contains('douglas.pl')) {
      return '$base/pl/search?q=$encodedQuery';
    }
    if (lower.contains('makeup.pl')) {
      return '$base/search/?q=$encodedQuery';
    }
    if (base.contains('?')) {
      return '$base$encodedQuery';
    }
    return '$base/search?q=$encodedQuery';
  }

  factory CustomStoreConfig.fromJson(Map<String, dynamic> json) {
    return CustomStoreConfig(
      name: json['name'] as String,
      searchUrlTemplate: json['search_url_template'] as String,
      isBuiltIn: json['is_built_in'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'search_url_template': searchUrlTemplate,
        'is_built_in': isBuiltIn,
      };
}

class StoreOffer {
  const StoreOffer({
    required this.store,
    required this.productTitle,
    required this.searchUrl,
    required this.note,
    this.pricePln,
    this.currency = 'PLN',
    this.inStock = true,
  });

  final String store;
  final String productTitle;
  final double? pricePln;
  final String currency;
  final bool inStock;
  final String searchUrl;
  final String note;

  factory StoreOffer.fromJson(Map<String, dynamic> json) {
    return StoreOffer(
      store: json['store'] as String,
      productTitle: json['product_title'] as String? ?? '',
      pricePln: (json['price_pln'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'PLN',
      inStock: json['in_stock'] as bool? ?? true,
      searchUrl: json['search_url'] as String,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'store': store,
        'product_title': productTitle,
        'price_pln': pricePln,
        'currency': currency,
        'in_stock': inStock,
        'search_url': searchUrl,
        'note': note,
      };
}

class UsageEstimate {
  const UsageEstimate({
    required this.dailyUsageAmount,
    required this.estimatedTotalDays,
    required this.expectedEndDate,
    required this.reminderDate,
    required this.explanation,
    this.usedAi = false,
  });

  final double dailyUsageAmount;
  final int estimatedTotalDays;
  final DateTime expectedEndDate;
  final DateTime reminderDate;
  final String explanation;
  final bool usedAi;

  factory UsageEstimate.fromJson(Map<String, dynamic> json) {
    return UsageEstimate(
      dailyUsageAmount: (json['daily_usage_amount'] as num).toDouble(),
      estimatedTotalDays: json['estimated_total_days'] as int,
      expectedEndDate: DateTime.parse(json['expected_end_date'] as String),
      reminderDate: DateTime.parse(json['reminder_date'] as String),
      explanation: json['explanation'] as String? ?? '',
      usedAi: json['used_ai'] as bool? ?? false,
    );
  }
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.totalVolume,
    required this.unit,
    required this.purchaseDate,
    required this.usageDescription,
    required this.dailyUsageAmount,
    required this.estimatedTotalDays,
    required this.expectedEndDate,
    required this.reminderDate,
    required this.reminderDaysBefore,
    required this.aiExplanation,
    required this.daysRemaining,
    required this.remainingPercentage,
    required this.needsRestockSoon,
    required this.storeLinks,
    this.brand,
    this.preferredStore,
    this.lastPricePln,
    this.customProductUrl,
    this.isFavorite = false,
    this.isEssential = false,
  });

  final int id;
  final String name;
  final String? brand;
  final ProductCategory category;
  final double totalVolume;
  final VolumeUnit unit;
  final DateTime purchaseDate;
  final String usageDescription;
  final double dailyUsageAmount;
  final int estimatedTotalDays;
  final DateTime expectedEndDate;
  final DateTime reminderDate;
  final int reminderDaysBefore;
  final String aiExplanation;
  final String? preferredStore;
  final double? lastPricePln;
  final String? customProductUrl;
  final bool isFavorite;
  final bool isEssential;
  final int daysRemaining;
  final double remainingPercentage;
  final bool needsRestockSoon;
  final List<StoreOffer> storeLinks;

  ProductItem copyWith({
    bool? isFavorite,
    bool? isEssential,
    List<StoreOffer>? storeLinks,
    DateTime? purchaseDate,
    DateTime? expectedEndDate,
    DateTime? reminderDate,
    int? daysRemaining,
    double? remainingPercentage,
    bool? needsRestockSoon,
  }) {
    return ProductItem(
      id: id,
      name: name,
      brand: brand,
      category: category,
      totalVolume: totalVolume,
      unit: unit,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      usageDescription: usageDescription,
      dailyUsageAmount: dailyUsageAmount,
      estimatedTotalDays: estimatedTotalDays,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderDaysBefore: reminderDaysBefore,
      aiExplanation: aiExplanation,
      preferredStore: preferredStore,
      lastPricePln: lastPricePln,
      customProductUrl: customProductUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isEssential: isEssential ?? this.isEssential,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      remainingPercentage: remainingPercentage ?? this.remainingPercentage,
      needsRestockSoon: needsRestockSoon ?? this.needsRestockSoon,
      storeLinks: storeLinks ?? this.storeLinks,
    );
  }

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['store_links'] as List<dynamic>? ?? const [];
    return ProductItem(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: ProductCategory.fromApi(json['category'] as String? ?? 'cosmetics'),
      totalVolume: (json['total_volume'] as num).toDouble(),
      unit: VolumeUnit.fromApi(json['unit'] as String? ?? 'ml'),
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      usageDescription: json['usage_description'] as String,
      dailyUsageAmount: (json['daily_usage_amount'] as num).toDouble(),
      estimatedTotalDays: json['estimated_total_days'] as int,
      expectedEndDate: DateTime.parse(json['expected_end_date'] as String),
      reminderDate: DateTime.parse(json['reminder_date'] as String),
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 5,
      aiExplanation: json['ai_explanation'] as String? ?? '',
      preferredStore: json['preferred_store'] as String?,
      lastPricePln: (json['last_price_pln'] as num?)?.toDouble(),
      customProductUrl: json['custom_product_url'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isEssential: json['is_essential'] as bool? ?? false,
      daysRemaining: json['days_remaining'] as int? ?? 0,
      remainingPercentage: (json['remaining_percentage'] as num?)?.toDouble() ?? 0.0,
      needsRestockSoon: json['needs_restock_soon'] as bool? ?? false,
      storeLinks: rawLinks
          .map((e) => StoreOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
