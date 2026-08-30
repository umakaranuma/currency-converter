import 'package:currency_converter/domain/services/conversion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ConversionService service = ConversionService();

  group('ConversionService.convert', () {
    test('multiplies the amount by each rate', () {
      final Map<String, double> result = service.convert(
        100,
        <String, double>{'EUR': 0.92, 'JPY': 149.0},
      );

      expect(result['EUR'], closeTo(92.0, 1e-9));
      expect(result['JPY'], closeTo(14900.0, 1e-9));
    });

    test('a zero amount yields zero for every known currency (not an empty UI)', () {
      final Map<String, double> result = service.convert(
        0,
        <String, double>{'EUR': 0.92, 'GBP': 0.79},
      );

      expect(result, <String, double>{'EUR': 0.0, 'GBP': 0.0});
    });

    test('a negative amount is treated as zero', () {
      final Map<String, double> result =
          service.convert(-5, <String, double>{'EUR': 0.92});

      expect(result['EUR'], 0.0);
    });

    test('empty rates produce an empty map without throwing', () {
      expect(service.convert(100, const <String, double>{}), isEmpty);
    });
  });
}
