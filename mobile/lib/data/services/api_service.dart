// API & Offline-Fallback Service for HomeReminder with Polish Store Query Translator & Paper/Towels AI Oracle
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../../domain/models/product_item.dart';

class HomeReminderApiService {
  HomeReminderApiService({
    this.baseUrl = 'http://127.0.0.1:8000/api/v1',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const Map<String, String> _ruToPlDictionary = {
    'туалетная бумага': 'papier toaletowy',
    'бумажные полотенца': 'ręcznik papierowy kuchenny',
    'бумажные салфетки': 'ręcznik papierowy chusteczki',
    'салфетки для кухни': 'ręcznik kuchenny papierowy',
    'кухонные полотенца': 'ręcznik kuchenny',
    'кухонные салфетки': 'serwetki kuchenne ręcznik',
    'салфетки': 'chusteczki serwetki',
    'гель для умывания': 'żel oczyszczający do twarzy',
    'пенка для умывания': 'pianka do mycia twarzy',
    'шампунь': 'szampon do włosów',
    'гель для душа': 'żel pod prysznic',
    'зубная паста': 'pasta do zębów',
    'жидкое мыло': 'mydło w płynie',
    'мыло': 'mydło',
    'крем для лица': 'krem do twarzy',
    'сыворотка': 'serum do twarzy',
    'мицеллярная вода': 'płyn micelarny',
    'гель для стирки': 'żel do prania',
    'стиральный порошок': 'proszek do prania',
    'кондиционер для белья': 'płyn do płukania',
    'средство для посуды': 'płyn do naczyń',
    'таблетки для посудомойки': 'tabletki do zmywarki',
    'универсальное средство': 'płyn uniwersalny',
  };

  /// Translates Russian product names into Polish search queries so Rossmann, Hebe, Allegro & Ekodrogeria find exact items.
  static String normalizePolishQuery(String rawQuery) {
    var q = rawQuery.trim().toLowerCase();
    for (final entry in _ruToPlDictionary.entries) {
      if (q.contains(entry.key)) {
        q = q.replaceAll(entry.key, entry.value);
      }
    }
    q = q.replaceAll(RegExp(r'\s+'), ' ').trim();
    return q.isEmpty ? rawQuery.trim() : q;
  }

  Future<List<ProductItem>> fetchItems({String? category, bool onlyRestockSoon = false}) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (onlyRestockSoon) queryParams['only_restock_soon'] = 'true';

    final uri = Uri.parse('$baseUrl/items').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final resp = await _client.get(uri).timeout(const Duration(seconds: 4));
    if (resp.statusCode != 200) {
      throw Exception('API Error ${resp.statusCode}');
    }
    final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
    return list.map((e) => ProductItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UsageEstimate> analyzeUsage({
    required String name,
    required ProductCategory category,
    required double totalVolume,
    required VolumeUnit unit,
    required String usageDescription,
    required DateTime purchaseDate,
    int reminderDaysBefore = 5,
    bool isPl = false,
  }) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$baseUrl/usage/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'category': category.apiValue,
              'total_volume': totalVolume,
              'unit': unit.apiValue,
              'usage_description': usageDescription,
              'purchase_date': purchaseDate.toIso8601String().split('T').first,
              'reminder_days_before': reminderDaysBefore,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        return UsageEstimate.fromJson(data);
      }
    } catch (_) {}
    return calculateLocalOracle(
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

  Future<ProductItem> createItem({
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
  }) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/items'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'brand': brand,
            'category': category.apiValue,
            'total_volume': totalVolume,
            'unit': unit.apiValue,
            'purchase_date': purchaseDate.toIso8601String().split('T').first,
            'usage_description': usageDescription,
            'reminder_days_before': reminderDaysBefore,
            'preferred_store': preferredStore,
            'last_price_pln': lastPricePln,
            'override_total_days': overrideTotalDays,
          }),
        )
        .timeout(const Duration(seconds: 4));

    if (resp.statusCode != 201) {
      throw Exception('Failed to create item: ${resp.statusCode}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return ProductItem.fromJson(data);
  }

  Future<ProductItem> restockItem(int id) async {
    final resp = await _client
        .post(Uri.parse('$baseUrl/items/$id/restock'))
        .timeout(const Duration(seconds: 4));
    if (resp.statusCode != 200) {
      throw Exception('Failed to restock item');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return ProductItem.fromJson(data);
  }

  Future<void> deleteItem(int id) async {
    await _client.delete(Uri.parse('$baseUrl/items/$id')).timeout(const Duration(seconds: 4));
  }

  Future<List<StoreOffer>> searchPolishStores(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/search').replace(queryParameters: {'q': query});
      final resp = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
        return list.map((e) => StoreOffer.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return buildPolishStoreLinksLocal(query);
  }

  static const List<CustomStoreConfig> builtInPolishStores = [
    CustomStoreConfig(
      name: 'Rossmann',
      searchUrlTemplate: 'https://www.rossmann.pl/szukaj?Search={query}',
      isBuiltIn: true,
    ),
    CustomStoreConfig(
      name: 'Hebe',
      searchUrlTemplate: 'https://www.hebe.pl/search?q={query}',
      isBuiltIn: true,
    ),
    CustomStoreConfig(
      name: 'Allegro',
      searchUrlTemplate: 'https://allegro.pl/listing?string={query}',
      isBuiltIn: true,
    ),
    CustomStoreConfig(
      name: 'Ekodrogeria',
      searchUrlTemplate: 'https://ekodrogeria.pl/s?q={query}',
      isBuiltIn: true,
    ),
  ];

  /// Builds direct search URLs for built-in + user-added online stores.
  static List<StoreOffer> buildPolishStoreLinksLocal(
    String query, {
    String? preferredStore,
    double? lastPrice,
    List<CustomStoreConfig> customStores = const [],
  }) {
    final normalized = normalizePolishQuery(query);
    final encoded = Uri.encodeQueryComponent(normalized);
    final allStores = [...builtInPolishStores, ...customStores];

    return allStores.map((cfg) {
      return StoreOffer(
        store: cfg.name,
        productTitle: normalized,
        pricePln: preferredStore == cfg.name ? lastPrice : null,
        searchUrl: cfg.buildSearchUrl(encoded),
        note: 'Szukaj "$normalized" w ${cfg.name}',
      );
    }).toList();
  }

  static UsageEstimate calculateLocalOracle({
    required String name,
    required ProductCategory category,
    required double totalVolume,
    required VolumeUnit unit,
    required String usageDescription,
    required DateTime purchaseDate,
    int reminderDaysBefore = 5,
    bool isPl = false,
  }) {
    final text = '$name $usageDescription'.toLowerCase();

    // 1. Detect number of people in household
    int people = 1;
    final peopleNumMatch = RegExp(r'(\d+)\s*(?:чел|люд|особ|osób|osoby|osoba)').firstMatch(text);
    if (peopleNumMatch != null) {
      people = int.tryParse(peopleNumMatch.group(1)!) ?? 1;
    } else if (text.contains('вдвоем') ||
        text.contains('вдвоём') ||
        text.contains('на двоих') ||
        text.contains('2 os')) {
      people = 2;
    } else if (text.contains('втроем') ||
        text.contains('втроём') ||
        text.contains('всей семь') ||
        text.contains('3 os')) {
      people = 3;
    } else if (text.contains('четверо') || text.contains('4 os')) {
      people = 4;
    }

    // 2. Special handling for Toilet Paper & Kitchen Towels / Napkins
    final isToiletPaper = text.contains('туалетн') || text.contains('papier toaletowy');
    final isKitchenTowel = text.contains('полотенц') ||
        text.contains('ręcznik') ||
        text.contains('кухн') ||
        text.contains('kuchen');
    final isNapkins = text.contains('салфетк') ||
        text.contains('serwetk') ||
        text.contains('chusteczk');

    if (isToiletPaper || isKitchenTowel || isNapkins || category == ProductCategory.paper) {
      double daily;
      if (isToiletPaper) {
        if (unit == VolumeUnit.rolls || unit == VolumeUnit.pcs) {
          // 1 person uses ~0.25 rolls of toilet paper per day (1 roll = 4 days for 1 person, 2 days for 2 people)
          daily = 0.25 * people;
        } else {
          daily = 30.0 * people; // in sheets
        }
      } else if (isKitchenTowel && (unit == VolumeUnit.rolls || unit == VolumeUnit.pcs)) {
        // Kitchen paper towel roll: ~0.15 rolls/day base + extra per person (~1 roll per 4-6 days)
        daily = 0.12 + (0.06 * people);
      } else {
        // Paper napkins / sheets in a box or pack (e.g., 100 sheets)
        double sheetsPerPersonDay = 4.0;
        if (text.contains('часто') || text.contains('активно') || text.contains('często')) {
          sheetsPerPersonDay = 7.0;
        }
        daily = unit == VolumeUnit.packs ? 0.08 * people : sheetsPerPersonDay * people;
      }

      final totalDays = math.max(1, (totalVolume / math.max(0.05, daily)).ceil());
      final endDate = purchaseDate.add(Duration(days: totalDays));
      final remDate = endDate.subtract(Duration(days: reminderDaysBefore));
      final unitStr = unit.label(isPl);

      final expl = isPl
          ? 'AI: ~${daily.toStringAsFixed(2)} $unitStr/dzień ($people os.) → wystarczy na $totalDays dni'
          : 'ИИ-расчёт: ~${daily.toStringAsFixed(2)} $unitStr/день ($people чел.) → хватит на $totalDays дн.';

      return UsageEstimate(
        dailyUsageAmount: double.parse(daily.toStringAsFixed(2)),
        estimatedTotalDays: totalDays,
        expectedEndDate: endDate,
        reminderDate: remDate,
        explanation: expl,
        usedAi: false,
      );
    }

    // 3. Standard Cosmetics & Household Chemistry calculation
    double timesPerDay = 1.0;
    if (text.contains('утром и вечером') ||
        text.contains('2 раза') ||
        text.contains('дважды') ||
        text.contains('2 razy') ||
        text.contains('rano i wieczorem')) {
      timesPerDay = 2.0;
    } else if (text.contains('3 раза') || text.contains('трижды') || text.contains('3 razy')) {
      timesPerDay = 3.0;
    } else if (text.contains('через день') || text.contains('co drugi dzień')) {
      timesPerDay = 0.5;
    } else if (text.contains('раз в неделю') || text.contains('raz w tygodniu')) {
      timesPerDay = 1 / 7.0;
    }

    double dose = unit == VolumeUnit.pcs || unit == VolumeUnit.washes ? 1.0 : 2.5;
    if (text.contains('шампун') ||
        text.contains('szampon') ||
        text.contains('гель для душ') ||
        text.contains('żel pod prysznic')) {
      dose = 10.0;
    } else if (text.contains('стирк') || text.contains('порошок') || text.contains('prani')) {
      dose = 50.0;
    } else if (text.contains('крем') ||
        text.contains('krem') ||
        text.contains('сыворот') ||
        text.contains('serum')) {
      dose = 1.2;
    } else if (text.contains('умыван') ||
        text.contains('мыло') ||
        text.contains('mydło') ||
        text.contains('паст') ||
        text.contains('pasta')) {
      dose = 2.0;
    }

    final daily = math.max(0.1, dose * timesPerDay * people);
    final totalDays = math.max(1, (totalVolume / daily).ceil());
    final endDate = purchaseDate.add(Duration(days: totalDays));
    final remDate = endDate.subtract(Duration(days: reminderDaysBefore));
    final unitStr = unit.label(isPl);

    final expl = isPl
        ? 'AI: ~${dose.toStringAsFixed(1)} $unitStr × ${timesPerDay.toStringAsFixed(1)}/dzień × $people os. = ${daily.toStringAsFixed(1)} $unitStr/dzień ($totalDays dni)'
        : 'ИИ-расчёт: ~${dose.toStringAsFixed(1)} $unitStr × ${timesPerDay.toStringAsFixed(1)} раз/день × $people чел. = ${daily.toStringAsFixed(1)} $unitStr/день (на $totalDays дн.)';

    return UsageEstimate(
      dailyUsageAmount: double.parse(daily.toStringAsFixed(2)),
      estimatedTotalDays: totalDays,
      expectedEndDate: endDate,
      reminderDate: remDate,
      explanation: expl,
      usedAi: false,
    );
  }
}
