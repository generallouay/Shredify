import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../models/meal_entry.dart';
import '../models/meal_food_item.dart';
import '../services/firestore_service.dart';

class MealRepository {
  final FirestoreService _fs;

  MealRepository(this._fs);

  Stream<List<Meal>> watchAll() {
    return _fs.meals.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs.map((d) => _mealFromDoc(d.id, d.data())).toList());
  }

  Future<Meal?> getById(String id) async {
    final doc = await _fs.meals.doc(id).get();
    if (!doc.exists) return null;
    return _mealFromDoc(doc.id, doc.data() ?? {});
  }

  Future<void> insert(Meal meal) async {
    await _fs.meals.doc(meal.id).set(_mealToDoc(meal));
  }

  Future<void> update(Meal meal) async {
    await _fs.meals.doc(meal.id).set(_mealToDoc(meal));
  }

  Future<void> delete(String id) async {
    await _fs.meals.doc(id).delete();
  }
}

Map<String, dynamic> _mealToDoc(Meal m) => {
      'createdAt': m.createdAt.millisecondsSinceEpoch,
      'items': m.items.map(_itemToDoc).toList(),
      'entries': m.entries.map(_entryToDoc).toList(),
    };

Map<String, dynamic> _itemToDoc(MealFoodItem i) => {
      'id': i.id,
      'foodId': i.foodId,
      'method': i.method.name,
      'weightGrams': i.weightGrams,
      'weightBefore': i.weightBefore,
      'weightAfter': i.weightAfter,
      'canCount': i.canCount,
      // Snapshot of the food at the time the meal was saved, so the meal
      // renders correctly even if the source food is later edited or deleted.
      'foodSnapshot': i.food == null
          ? null
          : {
              'id': i.food!.id,
              'name': i.food!.name,
              'kcal': i.food!.kcal,
              'protein': i.food!.protein,
              'fat': i.food!.fat,
              'carbs': i.food!.carbs,
              'type': i.food!.type.name,
              'canSize': i.food!.canSize,
              'photoUrl': i.food!.photoPath,
            },
    };

Map<String, dynamic> _entryToDoc(MealEntry e) => {
      'id': e.id,
      'kcal': e.kcal,
      'protein': e.protein,
      'carbs': e.carbs,
      'fat': e.fat,
      'description': e.description,
    };

Meal _mealFromDoc(String id, Map<String, dynamic> m) {
  final items = ((m['items'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((it) => _itemFromDoc(id, it))
      .toList();
  final entries = ((m['entries'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((e) => _entryFromDoc(id, e))
      .toList();
  return Meal(
    id: id,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
        (m['createdAt'] as num?)?.toInt() ?? 0),
    items: items,
    entries: entries,
  );
}

MealFoodItem _itemFromDoc(String mealId, Map<String, dynamic> m) {
  final snap = m['foodSnapshot'] as Map<String, dynamic>?;
  Food? food;
  if (snap != null) {
    food = Food(
      id: (snap['id'] as String?) ?? '',
      name: (snap['name'] as String?) ?? '',
      kcal: (snap['kcal'] as num?)?.toDouble() ?? 0,
      protein: (snap['protein'] as num?)?.toDouble() ?? 0,
      fat: (snap['fat'] as num?)?.toDouble() ?? 0,
      carbs: (snap['carbs'] as num?)?.toDouble() ?? 0,
      type: FoodType.values.byName((snap['type'] as String?) ?? 'standard'),
      canSize: (snap['canSize'] as num?)?.toDouble(),
      photoPath: snap['photoUrl'] as String?,
    );
  }
  return MealFoodItem(
    id: (m['id'] as String?) ?? '',
    mealId: mealId,
    foodId: (m['foodId'] as String?) ?? '',
    method:
        MeasurementMethod.values.byName((m['method'] as String?) ?? 'standard'),
    weightGrams: (m['weightGrams'] as num?)?.toDouble(),
    weightBefore: (m['weightBefore'] as num?)?.toDouble(),
    weightAfter: (m['weightAfter'] as num?)?.toDouble(),
    canCount: (m['canCount'] as num?)?.toDouble(),
    food: food,
  );
}

MealEntry _entryFromDoc(String mealId, Map<String, dynamic> m) => MealEntry(
      id: (m['id'] as String?) ?? '',
      mealId: mealId,
      kcal: (m['kcal'] as num?)?.toDouble() ?? 0,
      protein: (m['protein'] as num?)?.toDouble(),
      carbs: (m['carbs'] as num?)?.toDouble(),
      fat: (m['fat'] as num?)?.toDouble(),
      description: m['description'] as String?,
    );

final mealRepositoryProvider = Provider<MealRepository>(
    (ref) => MealRepository(ref.watch(firestoreServiceProvider)));
