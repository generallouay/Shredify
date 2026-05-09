import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/auth_provider.dart';

class PhotoStorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  PhotoStorageService(this._storage, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  /// If [pathOrUrl] is a remote https URL, returns it unchanged.
  /// If it's a local file path, uploads the file to Storage and returns the
  /// download URL.
  Future<String?> ensureRemote(String? pathOrUrl) async {
    if (pathOrUrl == null) return null;
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final file = File(pathOrUrl);
    if (!await file.exists()) return null;
    return uploadFile(file);
  }

  Future<String> uploadFile(File file) async {
    final uid = _uid;
    if (uid == null) throw StateError('No signed-in user');
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final name = '${DateTime.now().millisecondsSinceEpoch}_'
        '${file.path.hashCode.toUnsigned(32)}$ext';
    final ref = _storage.ref('users/$uid/photos/$name');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    if (!url.startsWith('http')) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}

bool isRemotePhoto(String? value) =>
    value != null &&
    (value.startsWith('http://') || value.startsWith('https://'));

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) =>
    PhotoStorageService(
        FirebaseStorage.instance, ref.watch(firebaseAuthProvider)));
