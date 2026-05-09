import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_goals.dart';
import '../services/firestore_service.dart';

class DailyGoalsRepository {
  final FirestoreService _fs;

  DailyGoalsRepository(this._fs);

  Stream<DailyGoals> watch() {
    return _fs.goalsDoc.snapshots().map((doc) {
      final m = doc.data();
      if (m == null) return const DailyGoals();
      return DailyGoals(
        kcal: (m['kcal'] as num?)?.toDouble() ?? 2000,
        protein: (m['protein'] as num?)?.toDouble() ?? 150,
        fat: (m['fat'] as num?)?.toDouble() ?? 65,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 200,
      );
    });
  }

  Future<void> save(DailyGoals goals) async {
    await _fs.goalsDoc.set({
      'kcal': goals.kcal,
      'protein': goals.protein,
      'fat': goals.fat,
      'carbs': goals.carbs,
    });
  }
}

final dailyGoalsRepositoryProvider = Provider<DailyGoalsRepository>(
    (ref) => DailyGoalsRepository(ref.watch(firestoreServiceProvider)));
