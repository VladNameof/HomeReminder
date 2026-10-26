// Repository for HomeReminder v0.3.0 with Custom Online Stores, Favorites, Essentials & Push Notifications
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/app_strings.dart';
import '../../domain/models/product_item.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class InventoryRepository {
  InventoryRepository({
    required HomeReminderApiService apiService,
    required NotificationService notificationService,
  })  : _api = apiService,
        _notifications = notificationService;

  final HomeReminderApiService _api;
  final NotificationService _notifications;

  static const String _cacheKey = 'homereminder_items_cache_v3';
  static const String _customStoresKey = 'homereminder_custom_stores_v1';
  static const String _langKey = 'homereminder_app_lang_v1';
  static const String _firstRunDoneKey = 'homereminder_first_run_done_v1';
  static const String _defaultReminderDaysKey = 'homereminder_default_rem_days_v1';

  Future<bool> isFirstRunCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunDoneKey) ?? false;
  }

  Future<AppLanguage> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langKey);
    return AppLanguage.fromCode(code);
  }

  Future<void> saveLanguage(AppLanguage lang, {bool markFirstRunCompleted = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang.code);
    if (markFirstRunCompleted) {
      await prefs.setBool(_firstRunDoneKey, true);
    }
  }

  Future<int> getDefaultReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_defaultReminderDaysKey) ?? 5;
  }

  Future<void> saveDefaultReminderDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultReminderDaysKey, days);
  }

  // --- Custom Online Stores Management ---

  Future<List<CustomStoreConfig>> getCustomStores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customStoresKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CustomStoreConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CustomStoreConfig>> getAllAvailableStores() async {
    final custom = await getCustomStores();
    return [...HomeReminderApiService.builtInPolishStores, ...custom];
  }

  Future<void> addCustomStore(String name, String urlOrTemplate) async {
    final cleanName = name.trim();
    final cleanUrl = urlOrTemplate.trim();
    if (cleanName.isEmpty || cleanUrl.isEmpty) return;

    final current = await getCustomStores();
    final updated = [
      ...current.where((s) => s.name.toLowerCase() != cleanName.toLowerCase()),
      CustomStoreConfig(name: cleanName, searchUrlTemplate: cleanUrl),
    ];
    await _saveCustomStores(updated);
  }

  Future<void> removeCustomStore(String name) async {
    final current = await getCustomStores();
    final updated = current
        .where((s) => s.name.toLowerCase() != name.toLowerCase())
        .toList();
    await _saveCustomStores(updated);
  }

  Future<void> _saveCustomStores(List<CustomStoreConfig> stores) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stores.map((s) => s.toJson()).toList());
    await prefs.setString(_customStoresKey, encoded);
  }

  // --- Inventory Loading & Filtering ---

  Future<List<ProductItem>> loadItems({
    ProductCategory? category,
    bool onlyRestockSoon = false,
    bool onlyFavorites = false,
    bool onlyEssentials = false,
    bool isPl = false,
  }) async {
    final allItems = await _loadLocalCache(isPl: isPl);
    return allItems.where((item) {
      if (category != null && item.category != category) return false;
      if (onlyRestockSoon && !item.needsRestockSoon) return false;
      if (onlyFavorites && !item.isFavorite) return false;
      if (onlyEssentials && !item.isEssential) return false;
      return true;
    }).toList();
  }

  Future<List<ProductItem>> loadAllUnfiltered({bool isPl = false}) {
    return _loadLocalCache(isPl: isPl);
  }

  Future<UsageEstimate> previewUsage({
    required String name,
    required ProductCategory category,
    required double totalVolume,
    required VolumeUnit unit,
    required String usageDescription,
    required DateTime purchaseDate,
    int reminderDaysBefore = 5,
    bool isPl = false,
  }) {
    return _api.analyzeUsage(
      name: name,
      category: category,
      totalVolume: totalVolume,
      unit: unit,
      usageDescription: usageDescription,
      purchaseDate: purchaseDate,
      reminderDaysBefore: reminderDaysBefore,
      isPl: isPl,
    );
  }

  Future<ProductItem> addItem({
    required String name,
    String? brand,
    required ProductCategory category,
    required double totalVolume,
    required VolumeUnit unit,
    required DateTime purchaseDate,
    required String usageDescription,
    int reminderDaysBefore = 5,
    String? preferredStore,
    double? lastPricePln,
    String? customProductUrl,
    bool isFavorite = false,
    bool isEssential = false,
    int? overrideTotalDays,
    bool isPl = false,
  }) async {
    final queryStr = brand != null && brand.isNotEmpty ? '$brand $name' : name;
    final customStores = await getCustomStores();

    final est = HomeReminderApiService.calculateLocalOracle(
      name: name,
      category: category,
      totalVolume: totalVolume,
      unit: unit,
      usageDescription: usageDescription,
      purchaseDate: purchaseDate,
      reminderDaysBefore: reminderDaysBefore,
      isPl: isPl,
    );
    final totalDays = overrideTotalDays ?? est.estimatedTotalDays;
    final endDate = purchaseDate.add(Duration(days: totalDays));
    final remDate = endDate.subtract(Duration(days: reminderDaysBefore));
    final daysRem = endDate.difference(DateTime.now()).inDays;
    final pct = (daysRem / totalDays * 100.0).clamp(0.0, 100.0);

    final created = ProductItem(
      id: DateTime.now().millisecondsSinceEpoch % 1000000,
      name: name,
      brand: brand,
      category: category,
      totalVolume: totalVolume,
      unit: unit,
      purchaseDate: purchaseDate,
      usageDescription: usageDescription,
      dailyUsageAmount: est.dailyUsageAmount,
      estimatedTotalDays: totalDays,
      expectedEndDate: endDate,
      reminderDate: remDate,
      reminderDaysBefore: reminderDaysBefore,
      aiExplanation: est.explanation,
      preferredStore: preferredStore ?? 'Rossmann',
      lastPricePln: lastPricePln,
      customProductUrl: customProductUrl != null && customProductUrl.trim().isNotEmpty
          ? customProductUrl.trim()
          : null,
      isFavorite: isFavorite,
      isEssential: isEssential,
      daysRemaining: daysRem,
      remainingPercentage: double.parse(pct.toStringAsFixed(1)),
      needsRestockSoon: daysRem <= reminderDaysBefore,
      storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
        queryStr,
        preferredStore: preferredStore,
        lastPrice: lastPricePln,
        customStores: customStores,
      ),
    );

    final current = await _loadLocalCache(isPl: isPl);
    final updated = [created, ...current.where((e) => e.id != created.id)];
    await _saveLocalCache(updated);
    await _notifications.scheduleProductReminder(created);
    return created;
  }

  Future<void> toggleFavorite(int id, {bool isPl = false}) async {
    final current = await _loadLocalCache(isPl: isPl);
    final updated = current
        .map((e) => e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e)
        .toList();
    await _saveLocalCache(updated);
  }

  Future<void> toggleEssential(int id, {bool isPl = false}) async {
    final current = await _loadLocalCache(isPl: isPl);
    final updated = current
        .map((e) => e.id == id ? e.copyWith(isEssential: !e.isEssential) : e)
        .toList();
    await _saveLocalCache(updated);
  }

  Future<ProductItem> restockItem(ProductItem item, {bool isPl = false}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: item.estimatedTotalDays));
    final remDate = endDate.subtract(Duration(days: item.reminderDaysBefore));
    final refreshed = item.copyWith(
      purchaseDate: now,
      expectedEndDate: endDate,
      reminderDate: remDate,
      daysRemaining: item.estimatedTotalDays,
      remainingPercentage: 100.0,
      needsRestockSoon: false,
    );
    final current = await _loadLocalCache(isPl: isPl);
    final updated = current.map((e) => e.id == item.id ? refreshed : e).toList();
    await _saveLocalCache(updated);
    await _notifications.scheduleProductReminder(refreshed);
    return refreshed;
  }

  Future<void> deleteItem(int id, {bool isPl = false}) async {
    final current = await _loadLocalCache(isPl: isPl);
    await _saveLocalCache(current.where((e) => e.id != id).toList());
  }

  Future<void> resetDemoItems({bool isPl = false}) async {
    final customStores = await getCustomStores();
    final demos = _seedDefaultDemoItems(isPl: isPl, customStores: customStores);
    await _saveLocalCache(demos);
  }

  Future<void> sendTestPush(ProductItem item) {
    return _notifications.triggerInstantTestPush(item);
  }

  Future<void> _saveLocalCache(List<ProductItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      items
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'brand': e.brand,
              'category': e.category.apiValue,
              'total_volume': e.totalVolume,
              'unit': e.unit.apiValue,
              'purchase_date': e.purchaseDate.toIso8601String().split('T').first,
              'usage_description': e.usageDescription,
              'daily_usage_amount': e.dailyUsageAmount,
              'estimated_total_days': e.estimatedTotalDays,
              'expected_end_date': e.expectedEndDate.toIso8601String().split('T').first,
              'reminder_date': e.reminderDate.toIso8601String().split('T').first,
              'reminder_days_before': e.reminderDaysBefore,
              'ai_explanation': e.aiExplanation,
              'preferred_store': e.preferredStore,
              'last_price_pln': e.lastPricePln,
              'custom_product_url': e.customProductUrl,
              'is_favorite': e.isFavorite,
              'is_essential': e.isEssential,
              'days_remaining': e.daysRemaining,
              'remaining_percentage': e.remainingPercentage,
              'needs_restock_soon': e.needsRestockSoon,
              'store_links': e.storeLinks.map((s) => s.toJson()).toList(),
            },
          )
          .toList(),
    );
    await prefs.setString(_cacheKey, encoded);
  }

  Future<List<ProductItem>> _loadLocalCache({bool isPl = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final customStores = await getCustomStores();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return _seedDefaultDemoItems(isPl: isPl, customStores: customStores);
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final item = ProductItem.fromJson(e as Map<String, dynamic>);
        final queryStr = item.brand != null && item.brand!.isNotEmpty
            ? '${item.brand} ${item.name}'
            : item.name;
        return item.copyWith(
          storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
            queryStr,
            preferredStore: item.preferredStore,
            lastPrice: item.lastPricePln,
            customStores: customStores,
          ),
        );
      }).toList();
    } catch (_) {
      return _seedDefaultDemoItems(isPl: isPl, customStores: customStores);
    }
  }

  List<ProductItem> _seedDefaultDemoItems({
    bool isPl = false,
    List<CustomStoreConfig> customStores = const [],
  }) {
    final now = DateTime.now();

    final tpPurchased = now.subtract(const Duration(days: 13));
    final tpEnd = tpPurchased.add(const Duration(days: 16));

    final ktPurchased = now.subtract(const Duration(days: 3));
    final ktEnd = ktPurchased.add(const Duration(days: 10));

    final cvPurchased = now.subtract(const Duration(days: 45));
    final cvEnd = cvPurchased.add(const Duration(days: 50));

    return [
      ProductItem(
        id: 101,
        name: isPl ? 'Papier toaletowy 3-warstwowy' : 'Туалетная бумага 3-слойная',
        brand: 'Velvet',
        category: ProductCategory.paper,
        totalVolume: 8,
        unit: VolumeUnit.rolls,
        purchaseDate: tpPurchased,
        usageDescription: isPl ? '2 osoby w domu' : 'Живём вдвоём (2 человека)',
        dailyUsageAmount: 0.5,
        estimatedTotalDays: 16,
        expectedEndDate: tpEnd,
        reminderDate: tpEnd.subtract(const Duration(days: 4)),
        reminderDaysBefore: 4,
        aiExplanation: isPl
            ? 'AI: ~0.50 rol./dzień (2 os.) → wystarczy na 16 dni'
            : 'ИИ-расчёт: ~0.50 рул./день (2 чел.) → хватит на 16 дн.',
        preferredStore: 'Rossmann',
        lastPricePln: 18.99,
        isFavorite: false,
        isEssential: true, // Always buy!
        daysRemaining: 3,
        remainingPercentage: 18.8,
        needsRestockSoon: true,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          'Velvet papier toaletowy 8 rolek',
          preferredStore: 'Rossmann',
          lastPrice: 18.99,
          customStores: customStores,
        ),
      ),
      ProductItem(
        id: 102,
        name: isPl ? 'Ręcznik papierowy kuchenny' : 'Бумажные салфетки / полотенца для кухни',
        brand: 'Foxy Mega',
        category: ProductCategory.paper,
        totalVolume: 2,
        unit: VolumeUnit.rolls,
        purchaseDate: ktPurchased,
        usageDescription: isPl
            ? 'Codzienne wycieranie rąk i blatów w kuchni (2 os.)'
            : 'Вытираем руки и стол на кухне каждый день (2 чел.)',
        dailyUsageAmount: 0.2,
        estimatedTotalDays: 10,
        expectedEndDate: ktEnd,
        reminderDate: ktEnd.subtract(const Duration(days: 3)),
        reminderDaysBefore: 3,
        aiExplanation: isPl
            ? 'AI: ~0.20 rol./dzień w kuchni → wystarczy na 10 dni'
            : 'ИИ-расчёт: ~0.20 рул./день на кухне → хватит на 10 дн.',
        preferredStore: 'Allegro',
        lastPricePln: 12.49,
        isFavorite: true,
        isEssential: true, // Always buy!
        daysRemaining: 7,
        remainingPercentage: 70.0,
        needsRestockSoon: false,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          'Foxy ręcznik papierowy kuchenny',
          preferredStore: 'Allegro',
          lastPrice: 12.49,
          customStores: customStores,
        ),
      ),
      ProductItem(
        id: 103,
        name: 'CeraVe Żel Oczyszczający',
        brand: 'CeraVe',
        category: ProductCategory.cosmetics,
        totalVolume: 400,
        unit: VolumeUnit.ml,
        purchaseDate: cvPurchased,
        usageDescription: isPl
            ? 'Myjemy twarz we dwoje rano i wieczorem'
            : 'Умываемся вдвоём утром и вечером',
        dailyUsageAmount: 8.0,
        estimatedTotalDays: 50,
        expectedEndDate: cvEnd,
        reminderDate: cvEnd.subtract(const Duration(days: 5)),
        reminderDaysBefore: 5,
        aiExplanation: isPl
            ? 'AI: ~2 ml × 2/dzień × 2 os. = 8 ml/dzień (50 dni)'
            : 'ИИ-расчёт: ~2 мл × 2 раза/день × 2 чел. = 8 мл/день (50 дн.)',
        preferredStore: 'Hebe',
        lastPricePln: 52.99,
        isFavorite: true, // Favorite!
        isEssential: false,
        daysRemaining: 5,
        remainingPercentage: 10.0,
        needsRestockSoon: true,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          'CeraVe Żel Oczyszczający 400ml',
          preferredStore: 'Hebe',
          lastPrice: 52.99,
          customStores: customStores,
        ),
      ),
    ];
  }
}
