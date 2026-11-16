import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_local.dart';
import 'models.dart';
import 'steam.dart';

/// Supplied with --dart-define-from-file=env.json (see README).
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: LocalEnv.supabaseUrl);
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: LocalEnv.supabaseKey);
  static const rawgKey = String.fromEnvironment('RAWG_API_KEY', defaultValue: LocalEnv.rawgKey);
  static const redirect = 'gamestack://auth-callback';
}

SupabaseClient get sb => Supabase.instance.client;

class _Fallback implements Exception {
  final String reason;
  const _Fallback(this.reason);
}

class Rawg {
  static bool _viaProxy = false;

  static Future<Map<String, dynamic>> _direct(String path, Map<String, String> q) async {
    if (Env.rawgKey.isEmpty) throw 'RAWG key missing. Run with --dart-define-from-file=env.json';
    final uri = Uri.https('api.rawg.io', '/api/$path', {...q, 'key': Env.rawgKey});
    final r = await http.get(uri).timeout(const Duration(seconds: 6));
    if (r.statusCode == 401) throw 'RAWG rejected the API key (401). Check RAWG_API_KEY.';
    if (r.statusCode != 200) throw _Fallback('status ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static bool _unreachable(Object e) => e is SocketException || e is TimeoutException || e is HandshakeException || e is http.ClientException || e is _Fallback;

  static Future<Map<String, dynamic>> _get(String path, Map<String, String> q) async {
    if (!_viaProxy) {
      try {
        return await _direct(path, q);
      } catch (e) {
        if (!_unreachable(e)) rethrow;
        _viaProxy = true;
      }
    }
    try {
      final r = await sb.rpc('rawg_proxy', params: {'path': path, 'params': q}).timeout(const Duration(seconds: 25));
      return Map<String, dynamic>.from(r as Map);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' || e.code == '42883') {
        _viaProxy = false;
        throw 'api.rawg.io is unreachable from this network. Run supabase/rawg_proxy.sql once in the Supabase SQL editor to route game search through Supabase.';
      }
      throw e.message;
    }
  }

  static DateTime? _downUntil;
  static bool usingFallback = false;
  static bool get _rawgDown => _downUntil != null && DateTime.now().isBefore(_downUntil!);

  static Future<List<Game>> _discoverRawg(String term, DiscoverFilter filter) async {
    final j = await _get('games', {
      'page_size': '24',
      if (term.trim().isEmpty) 'ordering': '-added' else 'search': term.trim(),
      if (filter == DiscoverFilter.horror) 'tags': 'horror',
    });
    final games = (j['results'] as List).map((e) => Game.fromRawg(e as Map<String, dynamic>)).toList();
    return filter == DiscoverFilter.other ? games.where((g) => !g.horror).toList() : games;
  }

  static Future<List<Game>> discover(String term, [DiscoverFilter filter = DiscoverFilter.all]) async {
    if (!_rawgDown) {
      try {
        final r = await _discoverRawg(term, filter);
        usingFallback = false;
        return r;
      } catch (e) {
        if (e is String && e.contains('(401)')) rethrow;
        _downUntil = DateTime.now().add(const Duration(minutes: 5));
      }
    }
    usingFallback = true;
    try {
      return await Steam.discover(term, filter);
    } catch (e) {
      throw 'RAWG is down and Steam could not be reached either. ${friendly(e)}';
    }
  }

  static Future<Game> detail(int id) async {
    if (Steam.isSteamId(id)) return Steam.detail(id);
    if (_rawgDown) throw 'RAWG is down';
    return Game.fromRawg(await _get('games/$id', {}));
  }
}

class CollectionStore extends ChangeNotifier {
  List<Game> games = [];
  bool loading = false; String? error;

  Game? byRawg(int id) => games.where((g) => g.rawgId == id).firstOrNull;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      final rows = await sb.from('user_games').select().order('added_at', ascending: false);
      games = rows.map<Game>((r) => Game.fromRow(r)).toList();
    } catch (e) {
      error = friendly(e);
    }
    loading = false; notifyListeners();
  }

  Future<void> save(Game g) async {
    await sb.from('user_games').upsert(g.toRow(sb.auth.currentUser!.id), onConflict: 'user_id,rawg_game_id');
    await load();
  }

  Future<void> remove(Game g) async {
    await sb.from('user_games').delete().eq('id', g.entryId!);
    await load();
  }

  void clear() => games = []; // no notify: called while building the logged-out gate
}

final store = CollectionStore();

String friendly(Object e) {
  if (e is AuthException) return e.message;
  if (e is SocketException) return 'No connection. Check your network and try again.';
  if (e is TimeoutException) return 'The server is taking too long to respond. Please try again.';
  if (e is PostgrestException) return e.message;
  return e.toString();
}

class ProfileRepo {
  static Future<Map<String, dynamic>> get() async {
    final u = sb.auth.currentUser!;
    final row = await sb.from('profiles').select().eq('id', u.id).maybeSingle();
    return {'nickname': row?['nickname'] ?? u.userMetadata?['nickname'] ?? u.userMetadata?['name'] ?? u.email!.split('@').first,
      'avatar_url': row?['avatar_url'], 'email': u.email};
  }

  static Future<void> save(String nickname, {File? photo}) async {
    final id = sb.auth.currentUser!.id;
    String? url;
    if (photo != null) {
      final path = '$id/avatar.jpg';
      await sb.storage.from('avatars').upload(path, photo, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      url = '${sb.storage.from('avatars').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    }
    // The profile row is created by a DB trigger on sign-up, so only update it.
    await sb.from('profiles').update({'nickname': nickname, if (url != null) 'avatar_url': url}).eq('id', id);
  }

  static Future<void> deleteAccount() async {
    await sb.rpc('delete_my_account');
    try { await sb.auth.signOut(); } catch (_) {}
  }
}
