class MacroTotals {
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  const MacroTotals({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  MacroTotals operator +(MacroTotals other) => MacroTotals(
        kcal: kcal + other.kcal,
        protein: protein + other.protein,
        fat: fat + other.fat,
        carbs: carbs + other.carbs,
      );

  static const zero = MacroTotals(kcal: 0, protein: 0, fat: 0, carbs: 0);
}
