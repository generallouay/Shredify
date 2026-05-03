import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/food_dao.dart';
import '../database/meal_dao.dart';

final appDatabaseProvider =
    Provider<AppDatabase>((ref) => AppDatabase.instance);

final foodDaoProvider = Provider<FoodDao>(
    (ref) => FoodDao(ref.watch(appDatabaseProvider)));

final mealDaoProvider = Provider<MealDao>((ref) => MealDao(
      ref.watch(appDatabaseProvider),
      ref.watch(foodDaoProvider),
    ));
