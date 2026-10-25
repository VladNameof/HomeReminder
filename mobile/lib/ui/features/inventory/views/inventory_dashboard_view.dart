// HomeReminder UI Dashboard, First-Run Language Onboarding, Settings Panel, Toilet Paper/Towels AI & Polish Store Search
import 'package:flutter/material.dart';
import 'package:homereminder_mobile/core/i18n/app_strings.dart';
import 'package:homereminder_mobile/domain/models/product_item.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../view_models/inventory_view_model.dart';

class InventoryDashboardView extends StatelessWidget {
  const InventoryDashboardView({super.key, required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.showFirstRunLanguagePicker) {
          return _FirstRunLanguageScreen(viewModel: viewModel);
        }

        final s = viewModel.s;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sanitizer_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  s.appTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: s.settingsTitle,
                onPressed: () => _showSettingsSheet(context),
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                onPressed: viewModel.loadInventory,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddItemDialog(context),
            icon: const Icon(Icons.add),
            label: Text(s.addProductBtn),
          ),
          body: Column(
            children: [
              _FilterHeader(viewModel: viewModel),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.items.isEmpty
                        ? _EmptyInventoryState(s: s)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: viewModel.items.length,
                            itemBuilder: (context, index) {
                              final item = viewModel.items[index];
                              return _ProductCard(
                                item: item,
                                viewModel: viewModel,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddProductSheet(viewModel: viewModel),
    );
  }

  Future<void> _showSettingsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SettingsSheet(viewModel: viewModel),
    );
  }
}

class _FirstRunLanguageScreen extends StatelessWidget {
  const _FirstRunLanguageScreen({required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F766E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.sanitizer_outlined,
                        size: 48,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'HomeReminder PL',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Выберите язык / Wybierz język',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => viewModel.selectLanguage(AppLanguage.ru),
                        icon: const Text('🇷🇺', style: TextStyle(fontSize: 22)),
                        label: const Text(
                          'Русский язык',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => viewModel.selectLanguage(AppLanguage.pl),
                        icon: const Text('🇵🇱', style: TextStyle(fontSize: 22)),
                        label: const Text(
                          'Język polski',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Можно изменить в любой момент в Настройках (⚙️)\nMożesz zmienić w każdej chwili w Ustawieniach (⚙️)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final s = viewModel.s;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  Text(
                    s.settingsTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                s.languageLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(
                      value: AppLanguage.ru,
                      label: Text('🇷🇺 Русский'),
                    ),
                    ButtonSegment(
                      value: AppLanguage.pl,
                      label: Text('🇵🇱 Polski'),
                    ),
                  ],
                  selected: {viewModel.language},
                  onSelectionChanged: (sel) => viewModel.selectLanguage(sel.first),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.defaultReminderLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DropdownButton<int>(
                    value: viewModel.defaultReminderDays,
                    items: [2, 3, 5, 7, 10, 14]
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.updateDefaultReminderDays(val);
                    },
                  ),
                ],
              ),
              const Divider(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await viewModel.resetDemos();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.restore),
                  label: Text(s.resetDemoBtn),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final s = viewModel.s;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: Text(s.filterAll),
              selected: viewModel.selectedCategory == null && !viewModel.onlyRestockSoon,
              onSelected: (_) {
                viewModel.toggleRestockFilter(false);
                viewModel.setCategoryFilter(null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(s.filterRestockSoon(viewModel.restockSoonCount)),
              selected: viewModel.onlyRestockSoon,
              selectedColor: Colors.amber.shade100,
              onSelected: viewModel.toggleRestockFilter,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(s.catPaper),
              selected: viewModel.selectedCategory == ProductCategory.paper,
              onSelected: (sel) =>
                  viewModel.setCategoryFilter(sel ? ProductCategory.paper : null),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(s.catCosmetics),
              selected: viewModel.selectedCategory == ProductCategory.cosmetics,
              onSelected: (sel) =>
                  viewModel.setCategoryFilter(sel ? ProductCategory.cosmetics : null),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(s.catChemistry),
              selected: viewModel.selectedCategory == ProductCategory.chemistry,
              onSelected: (sel) =>
                  viewModel.setCategoryFilter(sel ? ProductCategory.chemistry : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.viewModel});

  final ProductItem item;
  final InventoryViewModel viewModel;

  Color _statusColor() {
    if (item.daysRemaining <= 3) return Colors.red.shade600;
    if (item.needsRestockSoon) return Colors.orange.shade700;
    return const Color(0xFF0F766E);
  }

  IconData _categoryIcon() {
    switch (item.category) {
      case ProductCategory.paper:
        return Icons.layers_outlined;
      case ProductCategory.cosmetics:
        return Icons.spa_outlined;
      case ProductCategory.chemistry:
        return Icons.cleaning_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    final progress = (item.remainingPercentage / 100.0).clamp(0.0, 1.0);
    final color = _statusColor();
    final s = viewModel.s;
    final isPl = viewModel.isPl;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: item.needsRestockSoon ? Colors.orange.shade300 : Colors.grey.shade200,
          width: item.needsRestockSoon ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  child: Icon(_categoryIcon()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.brand != null && item.brand!.isNotEmpty
                            ? '${item.brand} — ${item.name}'
                            : item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.purchasedOn}: ${df.format(item.purchaseDate)} • ${s.volumeLabel}: ${item.totalVolume.toStringAsFixed(0)} ${item.unit.label(isPl)}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.daysRemaining <= 0
                        ? s.endedStatus
                        : s.daysLeft(item.daysRemaining),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '🤖 ${item.aiExplanation}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Text(
                  s.untilDate(df.format(item.expectedEndDate)),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 22),
            Text(
              s.storesHeader,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.storeLinks.map((offer) {
                final isPreferred = offer.store == item.preferredStore;
                final priceTag = offer.pricePln != null
                    ? ' • ${offer.pricePln!.toStringAsFixed(2)} zł'
                    : '';
                return ActionChip(
                  avatar: Icon(
                    Icons.search,
                    size: 16,
                    color: isPreferred ? const Color(0xFF0F766E) : Colors.grey.shade700,
                  ),
                  backgroundColor:
                      isPreferred ? const Color(0xFFE6F4F1) : Colors.grey.shade100,
                  label: Text(
                    '${offer.store}$priceTag',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isPreferred ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(offer.searchUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    viewModel.triggerPushForProduct(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.pushScheduledSnack(df.format(item.reminderDate))),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: Text(s.testPushBtn),
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  onPressed: () => viewModel.restockProduct(item),
                  icon: const Icon(Icons.replay, size: 18),
                  label: Text(s.boughtAgainBtn),
                ),
                IconButton(
                  tooltip: s.deleteTooltip,
                  onPressed: () => viewModel.deleteProduct(item.id),
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.s});

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              s.emptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              s.emptyDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet({required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController(text: '8');
  final _usageCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _daysOverrideCtrl = TextEditingController();

  ProductCategory _category = ProductCategory.paper;
  VolumeUnit _unit = VolumeUnit.rolls;
  DateTime _purchaseDate = DateTime.now();
  String _preferredStore = 'Rossmann';

  UsageEstimate? _aiEstimate;
  bool _calculatingAi = false;

  @override
  void initState() {
    super.initState();
    _usageCtrl.text = widget.viewModel.isPl
        ? '2 osoby w domu, codzienne użycie'
        : 'Живём вдвоём (2 человека), используем каждый день';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _volumeCtrl.dispose();
    _usageCtrl.dispose();
    _priceCtrl.dispose();
    _daysOverrideCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String type) {
    final isPl = widget.viewModel.isPl;
    setState(() {
      if (type == 'tp') {
        _category = ProductCategory.paper;
        _unit = VolumeUnit.rolls;
        _nameCtrl.text = isPl ? 'Papier toaletowy 3-warstwowy' : 'Туалетная бумага';
        _brandCtrl.text = 'Velvet';
        _volumeCtrl.text = '8';
        _usageCtrl.text = isPl ? '2 osoby w domu' : '2 человека в доме';
      } else if (type == 'kt') {
        _category = ProductCategory.paper;
        _unit = VolumeUnit.rolls;
        _nameCtrl.text = isPl ? 'Ręcznik kuchenny papierowy' : 'Бумажные салфетки для кухни';
        _brandCtrl.text = 'Foxy';
        _volumeCtrl.text = '2';
        _usageCtrl.text = isPl ? 'Używamy w kuchni codziennie (2 os.)' : 'Используем на кухне каждый день (2 чел.)';
      } else {
        _category = ProductCategory.cosmetics;
        _unit = VolumeUnit.ml;
        _nameCtrl.text = isPl ? 'Żel oczyszczający do twarzy' : 'Гель для умывания';
        _brandCtrl.text = 'CeraVe';
        _volumeCtrl.text = '400';
        _usageCtrl.text = isPl ? 'Myjemy twarz we dwoje rano i wieczorem' : 'Умываемся вдвоём утром и вечером';
      }
    });
    _runAiEstimate();
  }

  Future<void> _runAiEstimate() async {
    final vol = double.tryParse(_volumeCtrl.text.replaceAll(',', '.')) ?? 8;
    final name = _nameCtrl.text.trim().isEmpty
        ? (_category == ProductCategory.paper ? 'Papier toaletowy' : 'Средство')
        : _nameCtrl.text.trim();
    setState(() => _calculatingAi = true);
    try {
      final res = await widget.viewModel.calculateAiUsage(
        name: name,
        category: _category,
        totalVolume: vol,
        unit: _unit,
        usageDescription: _usageCtrl.text.trim(),
        purchaseDate: _purchaseDate,
      );
      setState(() {
        _aiEstimate = res;
        _daysOverrideCtrl.text = res.estimatedTotalDays.toString();
      });
    } finally {
      if (mounted) setState(() => _calculatingAi = false);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final vol = double.tryParse(_volumeCtrl.text.replaceAll(',', '.')) ?? 1;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final overrideDays = int.tryParse(_daysOverrideCtrl.text.trim());

    await widget.viewModel.addProduct(
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      category: _category,
      totalVolume: vol,
      unit: _unit,
      purchaseDate: _purchaseDate,
      usageDescription: _usageCtrl.text.trim(),
      preferredStore: _preferredStore,
      lastPricePln: price,
      overrideTotalDays: overrideDays,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    final s = widget.viewModel.s;
    final isPl = widget.viewModel.isPl;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.newProductModalTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: Text(s.presetToiletPaper, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _applyPreset('tp'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(s.presetKitchenTowels, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _applyPreset('kt'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(s.presetFaceGel, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _applyPreset('gel'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ProductCategory>(
                segments: [
                  ButtonSegment(
                    value: ProductCategory.paper,
                    label: Text(s.catPaper, style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: ProductCategory.cosmetics,
                    label: Text(s.catCosmetics, style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: ProductCategory.chemistry,
                    label: Text(s.catChemistry, style: const TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (sel) {
                  setState(() {
                    _category = sel.first;
                    if (_category == ProductCategory.paper) {
                      _unit = VolumeUnit.rolls;
                    } else {
                      _unit = VolumeUnit.ml;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: s.nameFieldLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _brandCtrl,
                    decoration: InputDecoration(
                      labelText: s.brandFieldLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _volumeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.amountFieldLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<VolumeUnit>(
                  value: _unit,
                  items: VolumeUnit.values
                      .map((u) => DropdownMenuItem(value: u, child: Text(u.label(isPl))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _unit = v);
                  },
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _purchaseDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(df.format(_purchaseDate)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usageCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.howUsedLabel,
                hintText: s.howUsedHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _calculatingAi ? null : _runAiEstimate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_calculatingAi ? s.calculatingBtn : s.calcAiBtn),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _daysOverrideCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.enoughForDaysLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_aiEstimate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_aiEstimate!.explanation}\n${s.pushWillArrive(df.format(_aiEstimate!.reminderDate))}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F766E)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _preferredStore,
                    decoration: InputDecoration(
                      labelText: s.storeInPolandLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Rossmann', child: Text('Rossmann')),
                      DropdownMenuItem(value: 'Hebe', child: Text('Hebe')),
                      DropdownMenuItem(value: 'Allegro', child: Text('Allegro')),
                      DropdownMenuItem(value: 'Ekodrogeria', child: Text('Ekodrogeria')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _preferredStore = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.pricePlnLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(s.saveAndRemindBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
