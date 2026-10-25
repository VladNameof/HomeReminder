// Bilingual RU / PL localization dictionary for HomeReminder

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
      isPl ? 'Kup wkrótce ($count)' : 'Скоро купить ($count)';
  String get catCosmetics => isPl ? '🧴 Kosmetyki' : '🧴 Косметика';
  String get catChemistry => isPl ? '🧽 Chemia domowa' : '🧽 Бытовая химия';
  String get catPaper => isPl ? '🧻 Papier i ręczniki' : '🧻 Бумага и салфетки';

  String get addProductBtn => isPl ? 'Dodaj produkt' : 'Добавить средство';
  String get settingsTitle => isPl ? 'Ustawienia' : 'Настройки';
  String get languageLabel => isPl ? 'Język interfejsu' : 'Язык интерфейса';
  String get defaultReminderLabel => isPl
      ? 'Powiadomienie przed końcem (dni)'
      : 'Напоминать за (дней до конца)';
  String get resetDemoBtn => isPl
      ? 'Przywróć przykładowe produkty (z papierem i ręcznikami)'
      : 'Восстановить примеры (включая туалетную бумагу и салфетки)';

  String get purchasedOn => isPl ? 'Kupiono' : 'Куплено';
  String get volumeLabel => isPl ? 'Ilość' : 'Объём';
  String get endedStatus => isPl ? 'Skończyło się!' : 'Закончилось!';
  String daysLeft(int days) =>
      isPl ? 'Zostało $days dni' : 'Осталось $days дн.';
  String untilDate(String date) => isPl ? 'Do $date' : 'До $date';

  String get storesHeader => isPl
      ? '🇵🇱 Szukaj produktu bezpośrednio w sklepie:'
      : '🇵🇱 Найти этот товар напрямую в магазине Польши:';

  String get testPushBtn => isPl ? 'Test Push' : 'Тест Push';
  String pushScheduledSnack(String date) => isPl
      ? '🔔 Powiadomienie zaplanowane na $date (wysłano test)'
      : '🔔 Push-напоминание запланировано на $date (отправлен тест)';
  String get boughtAgainBtn => isPl ? 'Kupiono ponownie' : 'Купил снова';
  String get deleteTooltip => isPl ? 'Usuń' : 'Удалить';

  String get emptyTitle =>
      isPl ? 'Lista produktów jest pusta' : 'Список средств пуст';
  String get emptyDesc => isPl
      ? 'Dodaj kosmetyki, chemię domową, papier toaletowy lub ręczniki kuchenne, a AI obliczy zużycie i przypomni o zakupach.'
      : 'Добавьте косметику, химию, туалетную бумагу или кухонные салфетки — ИИ сам рассчитает расход и напомнит о покупке.';

  String get newProductModalTitle =>
      isPl ? 'Nowy produkt w domu' : 'Новое средство в дом';
  String get nameFieldLabel => isPl
      ? 'Nazwa (np. Papier toaletowy / Żel do mycia)'
      : 'Название (напр. Туалетная бумага / Гель)';
  String get brandFieldLabel => isPl ? 'Marka (np. Queen / CeraVe)' : 'Бренд (Mola / CeraVe)';
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
      isPl ? 'Sklep w Polsce' : 'Магазин в Польше';
  String get pricePlnLabel =>
      isPl ? 'Cena zakupu (PLN zł)' : 'Цена покупки (PLN zł)';
  String get saveAndRemindBtn => isPl
      ? 'Zapisz i włącz powiadomienie Push'
      : 'Сохранить и включить Push-напоминание';
  String pushWillArrive(String date) => isPl
      ? '🔔 Powiadomienie Push przyjdzie: $date'
      : '🔔 Пуш-напоминание придёт: $date';

  // Quick presets for fast adding (including Toilet Paper & Kitchen Towels!)
  String get quickPresetsLabel =>
      isPl ? 'Szybki wybór:' : 'Быстрый шаблон:';
  String get presetToiletPaper =>
      isPl ? '🧻 Papier toaletowy (8 rolek)' : '🧻 Туалетная бумага (8 рул.)';
  String get presetKitchenTowels =>
      isPl ? 'キッチン 🧻 Ręcznik kuchenny / Serwetki' : '🧻 Салфетки / Полотенца для кухни';
  String get presetFaceGel =>
      isPl ? '🧴 Żel do mycia (400 ml)' : '🧴 Гель для умывания (400 мл)';
}
