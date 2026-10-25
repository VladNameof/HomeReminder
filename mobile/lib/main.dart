// HomeReminder Flutter Application Entrypoint
import 'package:flutter/material.dart';

import 'data/repositories/inventory_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/notification_service.dart';
import 'ui/features/inventory/view_models/inventory_view_model.dart';
import 'ui/features/inventory/views/inventory_dashboard_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final apiService = HomeReminderApiService();
  final repository = InventoryRepository(
    apiService: apiService,
    notificationService: notificationService,
  );
  final viewModel = InventoryViewModel(repository: repository);
  await viewModel.initializeAppState();

  runApp(HomeReminderApp(viewModel: viewModel));
}

class HomeReminderApp extends StatelessWidget {
  const HomeReminderApp({super.key, required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeReminder PL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: InventoryDashboardView(viewModel: viewModel),
    );
  }
}
