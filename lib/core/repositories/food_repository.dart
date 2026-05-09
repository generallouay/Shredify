import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import '../services/firestore_service.dart';
import '../services/photo_storage_service.dart';

class FoodRepository {
  final FirestoreService _fs;
  final PhotoStorageService _photos;

  FoodRepository(this._fs, this._photos);

  Stream<List<Food>> watchAll() {
    return _fs.foods.orderBy('name').snapshots().map(
        (snap) => snap.docs.map((d) => _foodFromDoc(d.id, d.data())).toList());
  }

  Future<Food?> getById(String id) async {
    final doc = await _fs.foods.doc(id).get();
    if (!doc.exists) return null;
    return _foodFromDoc(doc.id, doc.data() ?? {});
  }

  Future<void> insert(Food food) async {
    final photoUrl = await _photos.ensureRemote(food.photoPath);
    await _fs.foods.doc(food.id).set(_foodToDoc(food.copyWith(
          photoPath: photoUrl,
          clearPhoto: photoUrl == null && food.photoPath == null,
        )));
  }

  Future<void> update(Food food) async {
    final photoUrl = await _photos.ensureRemote(food.photoPath);
    final existing = await getById(food.id);
    if (existing != null &&
        isRemotePhoto(existing.photoPath) &&
        existing.photoPath != photoUrl) {
      await _photos.deleteByUrl(existing.photoPath!);
    }
    await _fs.foods.doc(food.id).set(_foodToDoc(food.copyWith(
          photoPath: photoUrl,
          clearPhoto: photoUrl == null && food.photoPath == null,
        )));
  }

  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing != null && isRemotePhoto(existing.photoPath)) {
      await _photos.deleteByUrl(existing.photoPath!);
    }
    await _fs.foods.doc(id).delete();
  }
}

Map<String, dynamic> _foodToDoc(Food f) => {
      'name': f.name,
      'kcal': f.kcal,
      'protein': f.protein,
      'fat': f.fat,
      'carbs': f.carbs,
      'type': f.type.name,
      'canSize': f.canSize,
      'photoUrl': f.photoPath,
    };

Food _foodFromDoc(String id, Map<String, dynamic> m) => Food(
      id: id,
      name: (m['name'] as String?) ?? '',
      kcal: (m['kcal'] as num?)?.toDouble() ?? 0,
      protein: (m['protein'] as num?)?.toDouble() ?? 0,
      fat: (m['fat'] as num?)?.toDouble() ?? 0,
      carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
      type: FoodType.values.byName((m['type'] as String?) ?? 'standard'),
      canSize: (m['canSize'] as num?)?.toDouble(),
      photoPath: m['photoUrl'] as String?,
    );

final foodRepositoryProvider = Provider<FoodRepository>((ref) => FoodRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(photoStorageServiceProvider)));
