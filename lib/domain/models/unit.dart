enum Dimension { count, mass, volume }

/// Units convert only within their [Dimension], through its base unit
/// (`pcs`, `g` or `ml`).
enum Unit {
  pcs(Dimension.count, 1),
  g(Dimension.mass, 1),
  kg(Dimension.mass, 1000),
  ml(Dimension.volume, 1),
  l(Dimension.volume, 1000),
  tsp(Dimension.volume, 5),
  tbsp(Dimension.volume, 15),
  cup(Dimension.volume, 240);

  const Unit(this.dimension, this.baseFactor);

  final Dimension dimension;

  /// How many base units one of this unit holds.
  final double baseFactor;
}

/// An amount of a [Unit]. Every operation across dimensions (e.g. `g` and
/// `pcs`) returns `null`, which callers show as "amount unknown".
class Quantity {
  const Quantity(this.amount, this.unit);

  final double amount;
  final Unit unit;

  Quantity? convertTo(Unit target) => unit.dimension == target.dimension
      ? Quantity(amount * unit.baseFactor / target.baseFactor, target)
      : null;

  /// The sum, in this quantity's unit.
  Quantity? operator +(Quantity other) => _combine(other, 1);

  /// The difference, in this quantity's unit. It can be negative.
  Quantity? operator -(Quantity other) => _combine(other, -1);

  /// Negative, zero or positive like [Comparable.compareTo]; `null` when the
  /// quantities aren't comparable.
  int? compareTo(Quantity other) {
    final converted = other.convertTo(unit);
    return converted == null ? null : amount.compareTo(converted.amount);
  }

  Quantity? _combine(Quantity other, int sign) {
    final converted = other.convertTo(unit);
    return converted == null
        ? null
        : Quantity(amount + sign * converted.amount, unit);
  }

  @override
  String toString() => '$amount ${unit.name}';
}
