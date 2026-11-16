enum GameStatus {
  played('Played', 'played'), playing('Currently playing', 'currently_playing'), wishlist('Wishlist', 'want_to_play');
  final String label, key;
  const GameStatus(this.label, this.key);
  static GameStatus? parse(String? k) => values.where((s) => s.key == k).firstOrNull;
}

enum DiscoverFilter {
  all('All'),
  horror('Horror'),
  other('Other');

  final String label;
  const DiscoverFilter(this.label);
}

class Game {
  final int rawgId; final String title; final String? coverUrl, description, releaseDate;
  final List<String> genres; final GameStatus? status; final bool horror; final double? rating; final String? entryId;
  const Game({required this.rawgId, required this.title, this.coverUrl, this.description, this.releaseDate,
      this.genres = const [], this.status, this.horror = false, this.rating, this.entryId});

  String get year => (releaseDate != null && releaseDate!.length >= 4) ? releaseDate!.substring(0, 4) : '—';
  bool get saved => entryId != null;

  factory Game.fromRawg(Map<String, dynamic> j) => Game(
        rawgId: j['id'] as int, title: (j['name'] ?? 'Untitled') as String, coverUrl: j['background_image'] as String?,
        description: (j['description_raw'] as String?)?.trim(), releaseDate: j['released'] as String?,
        genres: ((j['genres'] as List?) ?? []).map((g) => g['name'] as String).toList(),
        // RAWG tags/genres only pre-select the Horror toggle; the user can override it.
        horror: [...((j['tags'] as List?) ?? []), ...((j['genres'] as List?) ?? [])].any((t) => '${t['slug']}'.contains('horror')));

  // Column names match the existing Supabase `user_games` table (supabase/migrations).
  factory Game.fromRow(Map<String, dynamic> r) => Game(
        rawgId: (r['rawg_game_id'] as num).toInt(), title: r['game_title'] as String, coverUrl: r['cover_url'] as String?,
        description: r['description'] as String?, releaseDate: r['release_date'] as String?,
        genres: ((r['genres'] as List?) ?? []).cast<String>(), status: GameStatus.parse(r['status'] as String?),
        horror: r['is_horror'] == true, rating: (r['personal_rating'] as num?)?.toDouble(), entryId: r['id'] as String?);

  Map<String, dynamic> toRow(String uid) => {
        'user_id': uid, 'rawg_game_id': rawgId, 'game_title': title, 'cover_url': coverUrl,
        'description': (description ?? '').length > 12000 ? description!.substring(0, 12000) : description,
        'release_date': (releaseDate ?? '').isEmpty ? null : releaseDate, 'genres': genres,
        'status': (status ?? GameStatus.wishlist).key, 'is_horror': horror, 'personal_rating': rating,
      };

  Game copyWith({GameStatus? status, bool? horror, double? rating, bool clearRating = false, String? description}) => Game(
        rawgId: rawgId, title: title, coverUrl: coverUrl, description: description ?? this.description, releaseDate: releaseDate,
        genres: genres, status: status ?? this.status, horror: horror ?? this.horror,
        rating: clearRating ? null : (rating ?? this.rating), entryId: entryId);
}

List<Game> filterGames(List<Game> all, GameStatus? status, bool horrorOnly) =>
    all.where((g) => (status == null || g.status == status) && (!horrorOnly || g.horror)).toList();

int countStatus(List<Game> all, GameStatus? s) => filterGames(all, s, false).length;

String? validateEmail(String? v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email';
String? validatePassword(String? v) => (v ?? '').length >= 8 ? null : 'At least 8 characters';
String? validateNickname(String? v) {
  final t = (v ?? '').trim();
  return t.length >= 2 && t.length <= 24 ? null : '2–24 characters';
}
