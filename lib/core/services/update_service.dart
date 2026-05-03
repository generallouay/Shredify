import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String version;
  final String releaseUrl;
  final String? releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.releaseNotes,
  });
}

class UpdateService {
  static const _owner = 'generallouay';
  static const _repo = 'Shredify';
  static const _skipKey = 'skip_update_version';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final prefs = await SharedPreferences.getInstance();
      final skipped = prefs.getString(_skipKey) ?? '';

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      ));
      req.headers.set('User-Agent', 'Shredify-Android/$currentVersion');
      req.headers.set('Accept', 'application/vnd.github.v3+json');

      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await resp.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final htmlUrl = (json['html_url'] as String?) ?? '';
      final notes = json['body'] as String?;

      if (tag.isEmpty || htmlUrl.isEmpty) return null;
      if (skipped == tag) return null;

      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      if (!_isNewer(latest, currentVersion)) return null;

      return UpdateInfo(
        version: tag,
        releaseUrl: htmlUrl,
        releaseNotes: (notes?.trim().isEmpty ?? true) ? null : notes,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> skipVersion(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipKey, tag);
  }

  static bool _isNewer(String latest, String current) {
    try {
      final l = latest.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      while (l.length < 3) l.add(0);
      while (c.length < 3) c.add(0);
      for (var i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
