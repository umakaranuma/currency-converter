import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/rates_local_datasource.dart';
import 'data/datasources/rates_remote_datasource.dart';
import 'data/repositories/currency_preferences_repository_impl.dart';
import 'data/repositories/rates_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/currency_preferences_repository.dart';
import 'domain/repositories/rates_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/services/conversion_service.dart';
import 'presentation/controllers/converter_controller.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/pages/converter_page.dart';

/// Composition root: the only place that wires concrete implementations
/// together (constructor injection, no DI package — see `agent/architecture.md`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final RatesRepository ratesRepository = RatesRepositoryImpl(
    HttpRatesRemoteDataSource(http.Client()),
    SharedPrefsRatesLocalDataSource(prefs),
  );
  final CurrencyPreferencesRepository currencyPreferences =
      CurrencyPreferencesRepositoryImpl(prefs);
  final SettingsRepository settings = SharedPrefsSettingsRepository(prefs);

  final ConverterController controller = ConverterController(
    ratesRepository,
    currencyPreferences,
    conversionService: const ConversionService(),
  );
  final ThemeController themeController =
      ThemeController.fromRepository(settings);

  runApp(CurrencyConverterApp(
    controller: controller,
    themeController: themeController,
  ));
}

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final ConverterController controller;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'USD Currency Converter',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          home: ConverterPage(
            controller: controller,
            themeController: themeController,
          ),
        );
      },
    );
  }
}
