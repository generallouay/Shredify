class DailyGoals {
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  const DailyGoals({
    this.kcal = 2000,
    this.protein = 150,
    this.fat = 65,
    this.carbs = 200,
  });

  DailyGoals copyWith({
    double? kcal,
    double? protein,
    double? fat,
    double? carbs,
  }) =>
      DailyGoals(
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        fat: fat ?? this.fat,
        carbs: carbs ?? this.carbs,
      );
}
