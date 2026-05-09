import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_entry.dart';
import '../services/firestore_service.dart';

class QuickEntryRepository {
  final FirestoreService _fs;

  QuickEntryRepository(this._fs);

  Stream<List<QuickEntry>> watchAll() {
    return _fs.quickEntries
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _entryFromDoc(d.id, d.data())).toList());
  }

  Future<void> insert(QuickEntry entry) async {
    await _fs.quickEntries.doc(entry.id).set(_entryToDoc(entry));
  }

  Future<void> delete(String id) async {
    await _fs.quickEntries.doc(id).delete();
  }
}

Map<String, dynamic> _entryToDoc(QuickEntry e) => {
      'createdAt': e.createdAt.millisecondsSinceEpoch,
      'kcal': e.kcal,
      'protein': e.protein,
      'carbs': e.carbs,
      'fat': e.fat,
      'description': e.description,
    };

QuickEntry _entryFromDoc(String id, Map<String, dynamic> m) => QuickEntry(
      id: id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (m['createdAt'] as num?)?.toInt() ?? 0),
      kcal: (m['kcal'] as num?)?.toDouble() ?? 0,
      protein: (m['protein'] as num?)?.toDouble(),
      carbs: (m['carbs'] as num?)?.toDouble(),
      fat: (m['fat'] as num?)?.toDouble(),
      description: m['description'] as String?,
    );

final quickEntryRepositoryProvider = Provider<QuickEntryRepository>(
    (ref) => QuickEntryRepository(ref.watch(firestoreServiceProvider)));
