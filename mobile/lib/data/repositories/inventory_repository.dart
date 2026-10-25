// Repository for HomeReminder Inventory with Local Cache, Language Preferences & Push Notifications
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

  static const String _cacheKey = 'homereminder_items_cache_v2';
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

  Future<List<ProductItem>> loadItems({
    ProductCategory? category,
    bool onlyRestockSoon = false,
    bool isPl = false,
  }) async {
    try {
      final remoteItems = await _api.fetchItems(
        category: category?.apiValue,
        onlyRestockSoon: onlyRestockSoon,
      );
      if (category == null && !onlyRestockSoon) {
        await _saveLocalCache(remoteItems);
      }
      return remoteItems;
    } catch (_) {
      final cached = await _loadLocalCache(isPl: isPl);
      return cached.where((item) {
        if (category != null && item.category != category) return false;
        if (onlyRestockSoon && !item.needsRestockSoon) return false;
        return true;
      }).toList();
    }
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
    int? overrideTotalDays,
    bool isPl = false,
  }) async {
    ProductItem created;
    final queryStr = brand != null && brand.isNotEmpty ? '$brand $name' : name;

    try {
      created = await _api.createItem(
        name: name,
        brand: brand,
        category: category,
        totalVolume: totalVolume,
        unit: unit,
        purchaseDate: purchaseDate,
        usageDescription: usageDescription,
        reminderDaysBefore: reminderDaysBefore,
        preferredStore: preferredStore,
        lastPricePln: lastPricePln,
        overrideTotalDays: overrideTotalDays,
      );
    } catch (_) {
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

      created = ProductItem(
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
        daysRemaining: daysRem,
        remainingPercentage: double.parse(pct.toStringAsFixed(1)),
        needsRestockSoon: daysRem <= reminderDaysBefore,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          queryStr,
          preferredStore: preferredStore,
          lastPrice: lastPricePln,
        ),
      );
    }

    final current = await _loadLocalCache(isPl: isPl);
    final updated = [created, ...current.where((e) => e.id != created.id)];
    await _saveLocalCache(updated);
    await _notifications.scheduleProductReminder(created);
    return created;
  }

  Future<ProductItem> restockItem(ProductItem item, {bool isPl = false}) async {
    try {
      final refreshed = await _api.restockItem(item.id);
      await _notifications.scheduleProductReminder(refreshed);
      return refreshed;
    } catch (_) {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: item.estimatedTotalDays));
      final remDate = endDate.subtract(Duration(days: item.reminderDaysBefore));
      final refreshed = ProductItem(
        id: item.id,
        name: item.name,
        brand: item.brand,
        category: item.category,
        totalVolume: item.totalVolume,
        unit: item.unit,
        purchaseDate: now,
        usageDescription: item.usageDescription,
        dailyUsageAmount: item.dailyUsageAmount,
        estimatedTotalDays: item.estimatedTotalDays,
        expectedEndDate: endDate,
        reminderDate: remDate,
        reminderDaysBefore: item.reminderDaysBefore,
        aiExplanation: item.aiExplanation,
        preferredStore: item.preferredStore,
        lastPricePln: item.lastPricePln,
        daysRemaining: item.estimatedTotalDays,
        remainingPercentage: 100.0,
        needsRestockSoon: false,
        storeLinks: item.storeLinks,
      );
      final current = await _loadLocalCache(isPl: isPl);
      final updated = current.map((e) => e.id == item.id ? refreshed : e).toList();
      await _saveLocalCache(updated);
      await _notifications.scheduleProductReminder(refreshed);
      return refreshed;
    }
  }

  Future<void> deleteItem(int id, {bool isPl = false}) async {
    try {
      await _api.deleteItem(id);
    } catch (_) {}
    final current = await _loadLocalCache(isPl: isPl);
    await _saveLocalCache(current.where((e) => e.id != id).toList());
  }

  Future<void> resetDemoItems({bool isPl = false}) async {
    final demos = _seedDefaultDemoItems(isPl: isPl);
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
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return _seedDefaultDemoItems(isPl: isPl);
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final item = ProductItem.fromJson(e as Map<String, dynamic>);
        final queryStr = item.brand != null && item.brand!.isNotEmpty
            ? '${item.brand} ${item.name}'
            : item.name;
        // Refresh store links to ensure updated direct search URLs work on existing cached items
        return ProductItem(
          id: item.id,
          name: item.name,
          brand: item.brand,
          category: item.category,
          totalVolume: item.totalVolume,
          unit: item.unit,
          purchaseDate: item.purchaseDate,
          usageDescription: item.usageDescription,
          dailyUsageAmount: item.dailyUsageAmount,
          estimatedTotalDays: item.estimatedTotalDays,
          expectedEndDate: item.expectedEndDate,
          reminderDate: item.reminderDate,
          reminderDaysBefore: item.reminderDaysBefore,
          aiExplanation: item.aiExplanation,
          preferredStore: item.preferredStore,
          lastPricePln: item.lastPricePln,
          daysRemaining: item.daysRemaining,
          remainingPercentage: item.remainingPercentage,
          needsRestockSoon: item.needsRestockSoon,
          storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
            queryStr,
            preferredStore: item.preferredStore,
            lastPrice: item.lastPricePln,
          ),
        );
      }).toList();
    } catch (_) {
      return _seedDefaultDemoItems(isPl: isPl);
    }
  }

  List<ProductItem> _seedDefaultDemoItems({bool isPl = false}) {
    final now = DateTime.now();

    // 1. Toilet paper (8 rolls, 2 people -> 16 days total, purchased 13 days ago -> 3 days left!)
    final tpPurchased = now.subtract(const Duration(days: 13));
    final tpEnd = tpPurchased.add(const Duration(days: 16));

    // 2. Kitchen paper towels (2 mega rolls, 2 people -> 10 days total, purchased 3 days ago -> 7 days left)
    final ktPurchased = now.subtract(const Duration(days: 3));
    final ktEnd = ktPurchased.add(const Duration(days: 10));

    // 3. CeraVe Face Wash
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
        daysRemaining: 3,
        remainingPercentage: 18.8,
        needsRestockSoon: true,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          'Velvet papier toaletowy 8 rolek',
          preferredStore: 'Rossmann',
          lastPrice: 18.99,
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
        daysRemaining: 7,
        remainingPercentage: 70.0,
        needsRestockSoon: false,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          'Foxy ręcznik papierowy kuchenny',
          preferredStore: 'Allegro',
          lastPrice: 12.49,
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
        daysRemaining: 5,
        remainingPercentage: 10.0,
        needsRestockSoon: true,
        storeLinks: HomeReminderApiService.buildPolishStoreLinksLocal(
          'CeraVe Żel Oczyszczający 400ml',
          preferredStore: 'Hebe',
          lastPrice: 52.99,
        ),
      ),
    ];
  }
}
