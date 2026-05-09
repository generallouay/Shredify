import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../services/photo_storage_service.dart';

class RecipeRepository {
  final FirestoreService _fs;
  final PhotoStorageService _photos;

  RecipeRepository(this._fs, this._photos);

  Stream<List<Recipe>> watchAll() {
    return _fs.recipes.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => _recipeFromDoc(d.id, d.data())).toList());
  }

  Future<Recipe?> getById(String id) async {
    final doc = await _fs.recipes.doc(id).get();
    if (!doc.exists) return null;
    return _recipeFromDoc(doc.id, doc.data() ?? {});
  }

  Future<void> insert(Recipe recipe) async {
    final photoUrl = await _photos.ensureRemote(recipe.photoPath);
    await _fs.recipes.doc(recipe.id).set(_recipeToDoc(recipe.copyWith(
          photoPath: photoUrl,
          clearPhoto: photoUrl == null && recipe.photoPath == null,
        )));
  }

  Future<void> update(Recipe recipe) async {
    final photoUrl = await _photos.ensureRemote(recipe.photoPath);
    final existing = await getById(recipe.id);
    if (existing != null &&
        isRemotePhoto(existing.photoPath) &&
        existing.photoPath != photoUrl) {
      await _photos.deleteByUrl(existing.photoPath!);
    }
    await _fs.recipes.doc(recipe.id).set(_recipeToDoc(recipe.copyWith(
          photoPath: photoUrl,
          clearPhoto: photoUrl == null && recipe.photoPath == null,
        )));
  }

  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing != null && isRemotePhoto(existing.photoPath)) {
      await _photos.deleteByUrl(existing.photoPath!);
    }
    await _fs.recipes.doc(id).delete();
  }
}

Map<String, dynamic> _recipeToDoc(Recipe r) => {
      'name': r.name,
      'type': r.type.name,
      'servings': r.servings,
      'photoUrl': r.photoPath,
      'createdAt': r.createdAt.millisecondsSinceEpoch,
      'ingredients':
          r.ingredients.map(_ingredientToDoc).toList(growable: false),
      'steps': r.steps,
    };

Map<String, dynamic> _ingredientToDoc(RecipeIngredient i) => {
      'id': i.id,
      'foodId': i.foodId,
      'customName': i.customName,
      'weightGrams': i.weightGrams,
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

Recipe _recipeFromDoc(String id, Map<String, dynamic> m) {
  final ingredients = ((m['ingredients'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_ingredientFromDoc)
      .toList();
  final steps = ((m['steps'] as List?) ?? const [])
      .whereType<String>()
      .toList(growable: false);
  return Recipe(
    id: id,
    name: (m['name'] as String?) ?? '',
    type: RecipeType.values
        .byName((m['type'] as String?) ?? RecipeType.standard.name),
    servings: (m['servings'] as num?)?.toInt() ?? 1,
    photoPath: m['photoUrl'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
        (m['createdAt'] as num?)?.toInt() ?? 0),
    ingredients: ingredients,
    steps: steps,
  );
}

RecipeIngredient _ingredientFromDoc(Map<String, dynamic> m) {
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
  return RecipeIngredient(
    id: (m['id'] as String?) ?? '',
    foodId: m['foodId'] as String?,
    food: food,
    customName: m['customName'] as String?,
    weightGrams: (m['weightGrams'] as num?)?.toDouble() ?? 0,
  );
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) =>
    RecipeRepository(ref.watch(firestoreServiceProvider),
        ref.watch(photoStorageServiceProvider)));
