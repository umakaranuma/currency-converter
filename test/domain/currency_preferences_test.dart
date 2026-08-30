import 'package:currency_converter/domain/entities/currency_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyPreferences', () {
    test('withAdded appends a supported code and ignores duplicates/unknowns', () {
      const CurrencyPreferences base = CurrencyPreferences(<String>['EUR', 'GBP']);

      expect(base.withAdded('JPY').selected, <String>['EUR', 'GBP', 'JPY']);
      expect(identical(base.withAdded('EUR'), base), isTrue); // already present
      expect(identical(base.withAdded('ZZZ'), base), isTrue); // not supported
    });

    test('withRemoved drops a code but refuses to empty the list', () {
      const CurrencyPreferences two = CurrencyPreferences(<String>['EUR', 'GBP']);
      expect(two.withRemoved('EUR').selected, <String>['GBP']);

      const CurrencyPreferences one = CurrencyPreferences(<String>['EUR']);
      expect(identical(one.withRemoved('EUR'), one), isTrue);
    });

    test('reordered moves an item using onReorderItem index semantics', () {
      const CurrencyPreferences p =
          CurrencyPreferences(<String>['EUR', 'GBP', 'JPY']);
      // move index 0 to the end (post-removal index 2)
      expect(p.reordered(0, 2).selected, <String>['GBP', 'JPY', 'EUR']);
      // move index 2 to the front
      expect(p.reordered(2, 0).selected, <String>['JPY', 'EUR', 'GBP']);
    });

    test('sanitized removes unknown, duplicate, and base codes', () {
      final CurrencyPreferences p = CurrencyPreferences.sanitized(
        <String>['EUR', 'EUR', 'USD', 'ZZZ', 'JPY'],
      );
      expect(p.selected, <String>['EUR', 'JPY']);
    });

    test('sanitized falls back to defaults when nothing usable remains', () {
      final CurrencyPreferences p =
          CurrencyPreferences.sanitized(<String>['USD', 'ZZZ']);
      expect(p.selected, CurrencyPreferences.defaults.selected);
    });
  });
}
