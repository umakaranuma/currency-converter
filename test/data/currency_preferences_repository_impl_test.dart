import 'package:currency_converter/core/constants.dart';
import 'package:currency_converter/data/repositories/currency_preferences_repository_impl.dart';
import 'package:currency_converter/domain/entities/currency_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late CurrencyPreferencesRepositoryImpl repo;

  Future<void> seed(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    repo = CurrencyPreferencesRepositoryImpl(prefs);
  }

  test('load() returns the default selection when nothing is stored', () async {
    await seed(<String, Object>{});

    final CurrencyPreferences result = await repo.load();

    expect(result.selected, kDefaultSelection);
  });

  test('save() then load() round-trips a custom order', () async {
    await seed(<String, Object>{});
    const CurrencyPreferences custom =
        CurrencyPreferences(<String>['JPY', 'CHF', 'GBP']);

    await repo.save(custom);
    final CurrencyPreferences reloaded = await repo.load();

    expect(reloaded.selected, <String>['JPY', 'CHF', 'GBP']);
  });

  test('load() sanitizes stale / unknown / duplicate codes', () async {
    await seed(<String, Object>{
      kCurrencyPrefsKey: '["EUR","EUR","USD","ZZZ","INR"]',
    });

    final CurrencyPreferences result = await repo.load();

    expect(result.selected, <String>['EUR', 'INR']);
  });

  test('load() falls back to defaults on a corrupt blob and clears it', () async {
    await seed(<String, Object>{kCurrencyPrefsKey: 'not json at all'});

    final CurrencyPreferences result = await repo.load();

    expect(result.selected, kDefaultSelection);
    expect(prefs.getString(kCurrencyPrefsKey), isNull);
  });
}
