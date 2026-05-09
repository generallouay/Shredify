import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_goals.dart';
import '../repositories/daily_goals_repository.dart';
import 'auth_provider.dart';

class DailyGoalsNotifier extends StreamNotifier<DailyGoals> {
  @override
  Stream<DailyGoals> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream.value(const DailyGoals());
    return ref.watch(dailyGoalsRepositoryProvider).watch();
  }

  Future<void> save(DailyGoals goals) =>
      ref.read(dailyGoalsRepositoryProvider).save(goals);
}

final dailyGoalsProvider =
    StreamNotifierProvider<DailyGoalsNotifier, DailyGoals>(
        DailyGoalsNotifier.new);
