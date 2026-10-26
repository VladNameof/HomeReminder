// Bilingual RU / PL localization dictionary for HomeReminder v0.3.0

enum AppLanguage {
  ru('ru', 'Русский', '🇷🇺'),
  pl('pl', 'Polski', '🇵🇱');

  const AppLanguage(this.code, this.title, this.flag);
  final String code;
  final String title;
  final String flag;

  static AppLanguage fromCode(String? code) {
    if (code == 'pl') return AppLanguage.pl;
    return AppLanguage.ru;
  }
}

class AppStrings {
  const AppStrings(this.lang);
  final AppLanguage lang;

  bool get isPl => lang == AppLanguage.pl;

  String get appTitle => 'HomeReminder PL';
  String get subtitle => isPl
      ? 'Inteligentny zapas kosmetyków, chemii i papieru w domu'
      : 'Умный учёт косметики, бытовой химии и бумаги в доме';

  String get chooseLanguageTitle =>
      isPl ? 'Wybierz język aplikacji' : 'Выберите язык приложения';
  String get chooseLanguageSub => isPl
      ? 'Możesz go zmienić w dowolnym momencie w Ustawieniach (⚙️).'
      : 'Вы сможете в любой момент переключить его в панели Настроек (⚙️).';
  String get continueBtn => isPl ? 'Kontynuuj' : 'Продолжить';

  String get filterAll => isPl ? 'Wszystkie' : 'Все';
  String filterRestockSoon(int count) =>
      isPl ? '🔔 Kup wkrótce ($count)' : '🔔 Скоро купить ($count)';
  String filterFavorites(int count) =>
      isPl ? '❤️ Ulubione ($count)' : '❤️ Фавориты ($count)';
  String filterEssentials(int count) =>
      isPl ? '📌 Niezbędne ($count)' : '📌 Необходимое всегда ($count)';

  String get catCosmetics => isPl ? '🧴 Kosmetyki' : '🧴 Косметика';
  String get catChemistry => isPl ? '🧽 Chemia domowa' : '🧽 Бытовая химия';
  String get catPaper => isPl ? '🧻 Papier i ręczniki' : '🧻 Бумага и салфетки';

  String get addProductBtn => isPl ? 'Dodaj produkt' : 'Добавить средство';
  String get manageStoresBtn =>
      isPl ? 'Sklepy internetowe' : 'Интернет-магазины';
  String get settingsTitle => isPl ? 'Ustawienia' : 'Настройки';
  String get languageLabel => isPl ? 'Język interfejsu' : 'Язык интерфейса';
  String get defaultReminderLabel => isPl
      ? 'Powiadomienie przed końcem (dni)'
      : 'Напоминать за (дней до конца)';
  String get resetDemoBtn => isPl
      ? 'Przywróć przykładowe produkty'
      : 'Восстановить примеры товаров';

  String get purchasedOn => isPl ? 'Kupiono' : 'Куплено';
  String get volumeLabel => isPl ? 'Ilość' : 'Объём';
  String get endedStatus => isPl ? 'Skończyło się!' : 'Закончилось!';
  String daysLeft(int days) =>
      isPl ? 'Zostało $days dni' : 'Осталось $days дн.';
  String untilDate(String date) => isPl ? 'Do $date' : 'До $date';

  String get badgeFavorite => isPl ? '❤️ Ulubiony' : '❤️ Фаворит';
  String get badgeEssential =>
      isPl ? '📌 Zawsze kupujemy' : '📌 Покупаем всегда';
  String get toggleFavoriteTooltip =>
      isPl ? 'Dodaj/usuń z ulubionych' : 'В фавориты / убрать';
  String get toggleEssentialTooltip => isPl
      ? 'Oznacz jako niezbędne (kupowane zawsze)'
      : 'Отметить как самое необходимое (покупается всегда)';

  String get storesHeader => isPl
      ? '🇵🇱 Kup lub porównaj cenę w sklepie:'
      : '🇵🇱 Найти и купить в интернет-магазине:';
  String get directProductLinkBtn =>
      isPl ? '🔗 Link do produktu' : '🔗 Прямая ссылка';

  String get testPushBtn => isPl ? 'Test Push' : 'Тест Push';
  String pushScheduledSnack(String date) => isPl
      ? '🔔 Powiadomienie zaplanowane na $date (wysłano test)'
      : '🔔 Push-напоминание запланировано на $date (отправлен тест)';
  String get boughtAgainBtn => isPl ? 'Kupiono ponownie' : 'Купил снова';
  String get deleteTooltip => isPl ? 'Usuń' : 'Удалить';

  String get emptyTitle =>
      isPl ? 'Brak produktów na tej liście' : 'В этом списке пока пусто';
  String get emptyDesc => isPl
      ? 'Dodaj kosmetyki, chemię domową lub papier i oznacz ❤️ Ulubione lub 📌 Niezbędne (kupowane zawsze).'
      : 'Добавьте косметику, химию или бумагу и отмечайте ❤️ Фавориты или 📌 Самое необходимое (то, что покупается всегда).';

  String get newProductModalTitle =>
      isPl ? 'Nowy produkt w domu' : 'Новое средство в дом';
  String get nameFieldLabel => isPl
      ? 'Nazwa (np. Papier toaletowy / Żel do mycia)'
      : 'Название (напр. Туалетная бумага / Гель)';
  String get brandFieldLabel =>
      isPl ? 'Marka (np. Velvet / CeraVe)' : 'Бренд (Velvet / CeraVe)';
  String get amountFieldLabel => isPl ? 'Ilość / Objętość' : 'Объём / Кол-во';
  String get howUsedLabel => isPl
      ? 'Jak używasz? (do obliczeń AI)'
      : 'Как будет использоваться? (для ИИ-расчёта)';
  String get howUsedHint => isPl
      ? 'Np.: 2 osoby, 8 rolek / Używamy w kuchni codziennie'
      : 'Напр.: Семья 2 человека / Вытираем руки на кухне каждый день';
  String get calcAiBtn =>
      isPl ? '✨ Oblicz zużycie AI' : '✨ Рассчитать ИИ-расход';
  String get calculatingBtn => isPl ? 'Liczenie...' : 'Считаем...';
  String get enoughForDaysLabel =>
      isPl ? 'Wystarczy na (dni)' : 'Хватит на (дней)';
  String get storeInPolandLabel =>
      isPl ? 'Sklep internetowy' : 'Интернет-магазин';
  String get pricePlnLabel =>
      isPl ? 'Cena zakupu (PLN zł)' : 'Цена покупки (PLN zł)';
  String get customProductUrlLabel => isPl
      ? 'Bezpośredni link do produktu w sklepie (opcjonalnie)'
      : 'Прямая ссылка на товар в интернет-магазине (необязательно)';
  String get saveAndRemindBtn => isPl
      ? 'Zapisz i włącz powiadomienie Push'
      : 'Сохранить и включить Push-напоминание';
  String pushWillArrive(String date) => isPl
      ? '🔔 Powiadomienie Push przyjdzie: $date'
      : '🔔 Пуш-напоминание придёт: $date';

  String get markAsFavoriteLabel =>
      isPl ? '❤️ Dodaj do Ulubionych' : '❤️ Добавить в Фавориты';
  String get markAsEssentialLabel => isPl
      ? '📌 Niezbędne (kupowane zawsze)'
      : '📌 Самое необходимое (покупаем всегда)';

  // Custom Store Manager strings
  String get customStoresModalTitle => isPl
      ? '🛍️ Twoje sklepy internetowe'
      : '🛍️ Интернет-магазины для покупок';
  String get customStoresDesc => isPl
      ? 'Dodaj dowolny sklep w Polsce (np. Notino, Douglas, Super-Pharm, Ceneo, Drogeria Pigment). Możesz podać link wyszukiwania z {query} lub po prostu adres strony sklepu (np. https://notino.pl).'
      : 'Добавьте любой интернет-магазин (например: Notino, Super-Pharm, Douglas, Ceneo, Makeup.pl). Достаточно указать название и адрес сайта (напр. https://notino.pl).';
  String get storeNameInputLabel =>
      isPl ? 'Nazwa sklepu (np. Notino / Super-Pharm)' : 'Название магазина (напр. Notino / Makeup)';
  String get storeUrlInputLabel => isPl
      ? 'Adres strony lub link wyszukiwania (np. https://notino.pl)'
      : 'Адрес сайта или ссылка поиска (напр. https://notino.pl)';
  String get addStoreBtn => isPl ? 'Dodaj sklep' : 'Добавить магазин';
  String get builtInStoresHeader =>
      isPl ? 'Domyślne sklepy PL:' : 'Базовые магазины Польши:';
  String get userAddedStoresHeader =>
      isPl ? 'Dodane przez Ciebie sklepy:' : 'Добавленные вами магазины:';
  String get quickAddPopularStores =>
      isPl ? 'Szybkie dodawanie popularnych:' : 'Быстро добавить популярные в Польше:';

  // Quick presets for fast adding
  String get presetToiletPaper =>
      isPl ? '🧻 Papier toaletowy (8 rol.)' : '🧻 Туалетная бумага (8 рул.)';
  String get presetKitchenTowels =>
      isPl ? '🧻 Ręcznik kuchenny' : '🧻 Салфетки для кухни';
  String get presetFaceGel =>
      isPl ? '🧴 Żel do mycia (400 ml)' : '🧴 Гель для умывания (400 мл)';
}
