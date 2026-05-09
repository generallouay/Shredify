import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class FirestoreService {
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;

  FirestoreService(this._fs, this._auth) {
    _fs.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  String? get uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final id = uid;
    if (id == null) {
      throw StateError('No signed-in user');
    }
    return _fs.collection('users').doc(id);
  }

  CollectionReference<Map<String, dynamic>> get foods =>
      _userDoc.collection('foods');
  CollectionReference<Map<String, dynamic>> get meals =>
      _userDoc.collection('meals');
  CollectionReference<Map<String, dynamic>> get quickEntries =>
      _userDoc.collection('quickEntries');
  CollectionReference<Map<String, dynamic>> get recipes =>
      _userDoc.collection('recipes');

  DocumentReference<Map<String, dynamic>> get goalsDoc =>
      _userDoc.collection('settings').doc('goals');
  DocumentReference<Map<String, dynamic>> get migrationDoc =>
      _userDoc.collection('_meta').doc('migration');
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) =>
    FirestoreService(
        FirebaseFirestore.instance, ref.watch(firebaseAuthProvider)));
