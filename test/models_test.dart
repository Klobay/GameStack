import 'package:flutter_test/flutter_test.dart';
import 'package:gamestack/models.dart';
import 'package:gamestack/steam.dart';

void main() {
  const a = Game(rawgId: 1, title: 'A', status: GameStatus.played, horror: true, releaseDate: '2019-08-27');
  const b = Game(rawgId: 2, title: 'B', status: GameStatus.wishlist);

  test('filter by status and horror', () {
    expect(filterGames([a, b], GameStatus.played, false), [a]);
    expect(filterGames([a, b], null, true), [a]);
    expect(filterGames([a, b], GameStatus.wishlist, true), isEmpty);
    expect(countStatus([a, b], null), 2);
    expect(countStatus([a, b], GameStatus.wishlist), 1);
  });

  test('year and status parsing', () {
    expect(a.year, '2019');
    expect(b.year, '—');
    expect(GameStatus.parse('currently_playing'), GameStatus.playing);
    expect(GameStatus.parse('nope'), isNull);
  });

  test('RAWG json maps to Game and detects horror tags', () {
    final g = Game.fromRawg({
      'id': 7,
      'name': 'Alan Wake 2',
      'released': '2023-10-27',
      'background_image': 'https://media.rawg.io/media/games/x.jpg',
      'genres': [
        {'name': 'Action', 'slug': 'action'}
      ],
      'tags': [
        {'slug': 'survival-horror'}
      ],
    });
    expect(g.rawgId, 7);
    expect(g.genres, ['Action']);
    expect(g.horror, isTrue);
    expect(g.saved, isFalse);
  });

  test('row round trip keeps status key and rating', () {
    final g = a.copyWith(rating: 8.5);
    final row = g.toRow('user-1');
    expect(row['status'], 'played');
    expect(row['personal_rating'], 8.5);
    expect(row['release_date'], '2019-08-27');
  });

  test('copyWith can clear the rating', () {
    expect(a.copyWith(rating: 5).copyWith(clearRating: true).rating, isNull);
  });

  test('validators', () {
    expect(validateEmail('x@y.co'), isNull);
    expect(validateEmail('nope'), isNotNull);
    expect(validatePassword('short'), isNotNull);
    expect(validatePassword('longenough'), isNull);
    expect(validateNickname('Al'), isNull);
    expect(validateNickname('A'), isNotNull);
  });

  test('discover filters expose labels', () {
    expect(DiscoverFilter.values.map((f) => f.label), ['All', 'Horror', 'Other']);
  });

  test('steam release dates become ISO dates', () {
    expect(Steam.isoDate('25 Feb, 2022'), '2022-02-25');
    expect(Steam.isoDate('Feb 25, 2022'), '2022-02-25');
    expect(Steam.isoDate('2023'), '2023-01-01');
    expect(Steam.isoDate('Coming soon'), isNull);
  });

  test('steam ids never collide with RAWG ids', () {
    expect(Steam.isSteamId(Steam.base + 1245620), isTrue);
    expect(Steam.isSteamId(3498), isFalse);
  });
}
