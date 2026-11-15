import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/models/unit.dart';

void main() {
  void expectQuantity(Quantity? actual, double amount, Unit unit) {
    expect(actual, isNotNull);
    expect(actual!.unit, unit);
    expect(actual.amount, closeTo(amount, 1e-9));
  }

  test('the units are exactly the spec list', () {
    expect(Unit.values.map((u) => u.name), [
      'pcs',
      'g',
      'kg',
      'ml',
      'l',
      'tsp',
      'tbsp',
      'cup',
    ]);
  });

  group('AC-AF-5: convertTo', () {
    const cases = [
      (Quantity(1, Unit.kg), Unit.g, 1000.0),
      (Quantity(1.5, Unit.l), Unit.ml, 1500.0),
      (Quantity(2, Unit.tbsp), Unit.ml, 30.0),
      (Quantity(1, Unit.cup), Unit.l, 0.24),
      (Quantity(3, Unit.tsp), Unit.tbsp, 1.0),
      (Quantity(4, Unit.pcs), Unit.pcs, 4.0),
    ];
    for (final (from, to, amount) in cases) {
      test('$from → ${to.name} = $amount', () {
        expectQuantity(from.convertTo(to), amount, to);
      });
    }

    test('3 pcs → g is null', () {
      expect(const Quantity(3, Unit.pcs).convertTo(Unit.g), isNull);
    });

    test('mass and volume never convert into each other', () {
      expect(const Quantity(1, Unit.kg).convertTo(Unit.l), isNull);
      expect(const Quantity(1, Unit.cup).convertTo(Unit.g), isNull);
    });
  });

  group('AC-AF-5: arithmetic within a dimension', () {
    test('500 g + 1 kg = 1500 g', () {
      expectQuantity(
        const Quantity(500, Unit.g) + const Quantity(1, Unit.kg),
        1500,
        Unit.g,
      );
    });

    test('1 l − 250 ml = 0.75 l', () {
      expectQuantity(
        const Quantity(1, Unit.l) - const Quantity(250, Unit.ml),
        0.75,
        Unit.l,
      );
    });

    test('adding or subtracting across dimensions is null', () {
      expect(const Quantity(500, Unit.g) + const Quantity(2, Unit.pcs), isNull);
      expect(const Quantity(1, Unit.l) - const Quantity(1, Unit.kg), isNull);
    });
  });

  group('AC-AF-5: compareTo', () {
    test('compares through the base unit', () {
      const half = Quantity(500, Unit.g);
      expect(half.compareTo(const Quantity(1, Unit.kg)), lessThan(0));
      expect(half.compareTo(const Quantity(0.5, Unit.kg)), 0);
      expect(half.compareTo(const Quantity(0.4, Unit.kg)), greaterThan(0));
    });

    test('500 g against 2 pcs is not comparable (null)', () {
      expect(
        const Quantity(500, Unit.g).compareTo(const Quantity(2, Unit.pcs)),
        isNull,
      );
    });
  });
}
