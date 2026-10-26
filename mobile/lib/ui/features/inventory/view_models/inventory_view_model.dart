// ViewModel for HomeReminder v0.3.0 (Custom Stores, Favorites, Essentials/Always Buy)
import 'package:flutter/foundation.dart';
import 'package:homereminder_mobile/core/i18n/app_strings.dart';
import 'package:homereminder_mobile/data/repositories/inventory_repository.dart';
import 'package:homereminder_mobile/domain/models/product_item.dart';

class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel({required InventoryRepository repository}) : _repository = repository;

  final InventoryRepository _repository;

  List<ProductItem> _items = const [];
  List<ProductItem> get items => _items;

  List<ProductItem> _allUnfiltered = const [];

  List<CustomStoreConfig> _customStores = const [];
  List<CustomStoreConfig> get customStores => _customStores;

  List<CustomStoreConfig> _allStores = const [];
  List<CustomStoreConfig> get allStores => _allStores;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProductCategory? _selectedCategory;
  ProductCategory? get selectedCategory => _selectedCategory;

  bool _onlyRestockSoon = false;
  bool get onlyRestockSoon => _onlyRestockSoon;

  bool _onlyFavorites = false;
  bool get onlyFavorites => _onlyFavorites;

  bool _onlyEssentials = false;
  bool get onlyEssentials => _onlyEssentials;

  AppLanguage _language = AppLanguage.ru;
  AppLanguage get language => _language;
  bool get isPl => _language == AppLanguage.pl;
  AppStrings get s => AppStrings(_language);

  bool _showFirstRunLanguagePicker = false;
  bool get showFirstRunLanguagePicker => _showFirstRunLanguagePicker;

  int _defaultReminderDays = 5;
  int get defaultReminderDays => _defaultReminderDays;

  int get restockSoonCount => _allUnfiltered.where((e) => e.needsRestockSoon).length;
  int get favoritesCount => _allUnfiltered.where((e) => e.isFavorite).length;
  int get essentialsCount => _allUnfiltered.where((e) => e.isEssential).length;

  Future<void> initializeAppState() async {
    final completed = await _repository.isFirstRunCompleted();
    _language = await _repository.getSavedLanguage();
    _defaultReminderDays = await _repository.getDefaultReminderDays();
    _showFirstRunLanguagePicker = !completed;
    await loadInventory();
  }

  Future<void> selectLanguage(AppLanguage lang) async {
    _language = lang;
    _showFirstRunLanguagePicker = false;
    await _repository.saveLanguage(lang, markFirstRunCompleted: true);
    await loadInventory();
  }

  Future<void> updateDefaultReminderDays(int days) async {
    _defaultReminderDays = days;
    await _repository.saveDefaultReminderDays(days);
    notifyListeners();
  }

  Future<void> addCustomOnlineStore(String name, String url) async {
    await _repository.addCustomStore(name, url);
    await loadInventory();
  }

  Future<void> removeCustomOnlineStore(String name) async {
    await _repository.removeCustomStore(name);
    await loadInventory();
  }

  Future<void> resetDemos() async {
    await _repository.resetDemoItems(isPl: isPl);
    await loadInventory();
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customStores = await _repository.getCustomStores();
      _allStores = await _repository.getAllAvailableStores();
      _allUnfiltered = await _repository.loadAllUnfiltered(isPl: isPl);
      _items = await _repository.loadItems(
        category: _selectedCategory,
        onlyRestockSoon: _onlyRestockSoon,
        onlyFavorites: _onlyFavorites,
        onlyEssentials: _onlyEssentials,
        isPl: isPl,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAllFilters() {
    _selectedCategory = null;
    _onlyRestockSoon = false;
    _onlyFavorites = false;
    _onlyEssentials = false;
    loadInventory();
  }

  void setCategoryFilter(ProductCategory? category) {
    _selectedCategory = category;
    loadInventory();
  }

  void toggleRestockFilter(bool val) {
    _onlyRestockSoon = val;
    if (val) {
      _onlyFavorites = false;
      _onlyEssentials = false;
    }
    loadInventory();
  }

  void toggleFavoritesFilter(bool val) {
    _onlyFavorites = val;
    if (val) {
      _onlyRestockSoon = false;
      _onlyEssentials = false;
    }
    loadInventory();
  }

  void toggleEssentialsFilter(bool val) {
    _onlyEssentials = val;
    if (val) {
      _onlyRestockSoon = false;
      _onlyFavorites = false;
    }
    loadInventory();
  }

  Future<void> toggleFavoriteForProduct(int id) async {
    await _repository.toggleFavorite(id, isPl: isPl);
    await loadInventory();
  }

  Future<void> toggleEssentialForProduct(int id) async {
    await _repository.toggleEssential(id, isPl: isPl);
    await loadInventory();
  }

  Future<UsageEstimate> calculateAiUsage({
    required String name,
    required ProductCategory category,
    required double totalVolume,
    required VolumeUnit unit,
    required String usageDescription,
    required DateTime purchaseDate,
    int? reminderDaysBefore,
  }) {
    return _repository.previewUsage(
      name: name,
      category: category,
      totalVolume: totalVolume,
      unit: unit,
      usageDescription: usageDescription,
      purchaseDate: purchaseDate,
      reminderDaysBefore: reminderDaysBefore ?? _defaultReminderDays,
      isPl: isPl,
    );
  }

  Future<void> addProduct({
    required String name,
    String? brand,
    required ProductCategory category,
    required double totalVolume,
    required VolumeUnit unit,
    required DateTime purchaseDate,
    required String usageDescription,
    int? reminderDaysBefore,
    String? preferredStore,
    double? lastPricePln,
    String? customProductUrl,
    bool isFavorite = false,
    bool isEssential = false,
    int? overrideTotalDays,
  }) async {
    await _repository.addItem(
      name: name,
      brand: brand,
      category: category,
      totalVolume: totalVolume,
      unit: unit,
      purchaseDate: purchaseDate,
      usageDescription: usageDescription,
      reminderDaysBefore: reminderDaysBefore ?? _defaultReminderDays,
      preferredStore: preferredStore,
      lastPricePln: lastPricePln,
      customProductUrl: customProductUrl,
      isFavorite: isFavorite,
      isEssential: isEssential,
      overrideTotalDays: overrideTotalDays,
      isPl: isPl,
    );
    await loadInventory();
  }

  Future<void> restockProduct(ProductItem item) async {
    await _repository.restockItem(item, isPl: isPl);
    await loadInventory();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteItem(id, isPl: isPl);
    await loadInventory();
  }

  Future<void> triggerPushForProduct(ProductItem item) {
    return _repository.sendTestPush(item);
  }
}
