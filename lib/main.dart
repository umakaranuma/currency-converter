import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/rates_local_datasource.dart';
import 'data/datasources/rates_remote_datasource.dart';
import 'data/repositories/rates_repository_impl.dart';
import 'domain/repositories/rates_repository.dart';
import 'domain/services/conversion_service.dart';
import 'presentation/controllers/converter_controller.dart';
import 'presentation/pages/converter_page.dart';

/// Composition root: this is the only place that wires concrete implementations
/// together (constructor injection, no DI package — see `agent/architecture.md`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final RatesRepository repository = RatesRepositoryImpl(
    HttpRatesRemoteDataSource(http.Client()),
    SharedPrefsRatesLocalDataSource(prefs),
  );

  final ConverterController controller = ConverterController(
    repository,
    conversionService: const ConversionService(),
  );

  runApp(CurrencyConverterApp(controller: controller));
}

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key, required this.controller});

  final ConverterController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USD Currency Converter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: ConverterPage(controller: controller),
    );
  }
}
