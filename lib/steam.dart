import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class Steam {
  static const base = 2000000000;
  static bool isSteamId(int id) => id >= base;
  static String cover(int appId) => 'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/library_600x900.jpg';

  static Future<dynamic> _json(Uri uri) async {
    final r = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw 'Steam error (${r.statusCode})';
    return jsonDecode(r.body);
  }

  static Future<List<Game>> discover(String term, DiscoverFilter filter) async {
    final q = filter == DiscoverFilter.horror ? '${term.trim()} horror'.trim() : term.trim();
    final seen = <int>{};
    final out = <Game>[];
    void add(dynamic e) {
      final id = e['id'];
      final name = e['name'];
      final type = e['type'];
      if (id is! int || name is! String || (type is String && type != 'app') || !seen.add(id)) return;
      out.add(Game(rawgId: base + id, title: name, coverUrl: cover(id)));
    }

    if (q.isEmpty) {
      final j = await _json(Uri.https('store.steampowered.com', '/api/featuredcategories', {'l': 'english', 'cc': 'us'}));
      for (final k in const ['top_sellers', 'new_releases', 'specials']) {
        for (final e in ((j[k]?['items'] as List?) ?? const [])) {
          add(e);
        }
      }
    } else {
      final j = await _json(Uri.https('store.steampowered.com', '/api/storesearch/', {'term': q, 'l': 'english', 'cc': 'us'}));
      for (final e in ((j['items'] as List?) ?? const [])) {
        add(e);
      }
    }
    return out.take(24).toList();
  }

  static Future<Game> detail(int gameId) async {
    final id = gameId - base;
    final j = await _json(Uri.https('store.steampowered.com', '/api/appdetails', {'appids': '$id', 'l': 'english', 'cc': 'us'}));
    final d = j['$id'];
    if (d == null || d['success'] != true) throw 'Steam has no details for this game.';
    final data = Map<String, dynamic>.from(d['data'] as Map);
    final genres = ((data['genres'] as List?) ?? const []).map((g) => '${g['description']}').toList();
    final desc = '${data['short_description'] ?? ''}'.trim();
    final released = data['release_date'] is Map ? '${data['release_date']['date'] ?? ''}' : '';
    return Game(
      rawgId: gameId,
      title: '${data['name'] ?? 'Untitled'}',
      coverUrl: cover(id),
      description: desc.isEmpty ? null : desc,
      releaseDate: isoDate(released),
      genres: genres,
      horror: '$desc ${genres.join(' ')}'.toLowerCase().contains('horror'),
    );
  }

  static const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

  static String? isoDate(String s) {
    String two(String v) => v.padLeft(2, '0');
    final dayFirst = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*,?\s+(\d{4})').firstMatch(s);
    if (dayFirst != null) {
      final m = _months.indexOf(dayFirst[2]!.toLowerCase()) + 1;
      if (m > 0) return '${dayFirst[3]}-${two('$m')}-${two(dayFirst[1]!)}';
    }
    final monthFirst = RegExp(r'([A-Za-z]{3})[a-z]*\s+(\d{1,2}),?\s+(\d{4})').firstMatch(s);
    if (monthFirst != null) {
      final m = _months.indexOf(monthFirst[1]!.toLowerCase()) + 1;
      if (m > 0) return '${monthFirst[3]}-${two('$m')}-${two(monthFirst[2]!)}';
    }
    final year = RegExp(r'(\d{4})').firstMatch(s);
    return year == null ? null : '${year[1]}-01-01';
  }
}
