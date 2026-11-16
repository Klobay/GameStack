import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'services.dart';
import 'theme.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  final _lib = GlobalKey<_LibraryState>();
  final _disc = GlobalKey<_DiscoverState>();
  @override
  void initState() {
    super.initState();
    store.load();
  }

  void go(int v) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (v == i) return;
    if (i == 0) _lib.currentState?.resetSearch();
    if (i == 1) _disc.currentState?.resetSearch();
    setState(() => i = v);
  }

  @override
  Widget build(BuildContext c) {
    final tabs = [LibraryScreen(key: _lib), DiscoverScreen(key: _disc), const ProfileScreen()];
    return PopScope(
      canPop: i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) go(0);
      },
      child: Ambient(
        top: true,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(fit: StackFit.expand, children: [
              for (var k = 0; k < tabs.length; k++)
                Offstage(
                  offstage: k != i,
                  child: TickerMode(
                    enabled: k == i,
                    child: AnimatedOpacity(
                      opacity: k == i ? 1 : 0,
                      duration: const Duration(milliseconds: 240),
                      child: AnimatedSlide(offset: k == i ? Offset.zero : const Offset(0.04, 0), duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic, child: tabs[k]),
                    ),
                  ),
                ),
            ]),
          ),
          bottomNavigationBar: BottomNav(i, go),
        ),
      ),
    );
  }
}

double posterH(BuildContext c) => (MediaQuery.sizeOf(c).width - 68) / 2 * 1.5;

Future<void> openGame(BuildContext c, Game g, String back) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.push(c, slideRoute(GameDetailsScreen(game: g, backLabel: back)));
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryScreen> {
  final _q = TextEditingController();

  void resetSearch() {
    if (_q.text.isEmpty) return;
    setState(_q.clear);
  }

  GameStatus? f;
  bool horror = false;
  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _match(Game g, String q) => q.isEmpty || g.title.toLowerCase().contains(q) || g.genres.any((x) => x.toLowerCase().contains(q));

  Widget _tile(String label, int n, bool sel, VoidCallback onTap) => Expanded(
        child: Bounce(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 68,
            decoration: BoxDecoration(color: sel ? C.ink : C.bg, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: n.toDouble()),
                duration: const Duration(milliseconds: 600),
                builder: (_, v, __) => Text('${v.round()}', style: ts(20, color: sel ? C.onLime : C.ink2, w: FontWeight.w700)),
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, style: ts(10, color: sel ? C.onLime : C.muted, w: FontWeight.w600)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (_, __) {
          final all = store.games, q = _q.text.trim().toLowerCase();
          final list = all.where((g) => (f == null || g.status == f) && (!horror || g.horror) && _match(g, q)).toList();
          final cnt = {for (final s in GameStatus.values) s: all.where((g) => g.status == s).length};

          final head = Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ScreenTitle('My library'),
              const SizedBox(height: 16),
              SearchBox(_q, 'Search your games', onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              Stack(alignment: Alignment.centerRight, children: [
                Container(
                  height: 92,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                  child: Row(children: [
                    _tile('ALL', all.length, f == null, () => setState(() => f = null)),
                    const SizedBox(width: 8),
                    _tile('PLAYING', cnt[GameStatus.playing] ?? 0, f == GameStatus.playing, () => setState(() => f = GameStatus.playing)),
                    const SizedBox(width: 8),
                    _tile('PLAYED', cnt[GameStatus.played] ?? 0, f == GameStatus.played, () => setState(() => f = GameStatus.played)),
                    const SizedBox(width: 8),
                    _tile('WISHLIST', cnt[GameStatus.wishlist] ?? 0, f == GameStatus.wishlist, () => setState(() => f = GameStatus.wishlist)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.only(right: 11), child: Container(width: 4, height: 24, decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(100)))),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${list.length} ${list.length == 1 ? 'GAME' : 'GAMES'}', style: ts(12, color: C.ink2, w: FontWeight.w600)),
                Bounce(
                  onTap: () => setState(() => horror = !horror),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: horror ? C.limeDeep : C.card, borderRadius: BorderRadius.circular(100), border: Border.all(color: horror ? C.lime : C.line)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.filter_alt_outlined, size: 12, color: horror ? C.lime : C.ink2),
                      const SizedBox(width: 6),
                      Text('Horror only', style: ts(11, color: horror ? C.lime : C.ink2, w: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ]),
          );

          if (store.loading && all.isEmpty) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrandBar(),
              const Padding(padding: EdgeInsets.fromLTRB(28, 10, 28, 20), child: ScreenTitle('My library')),
              const SkeletonGrid(),
            ]);
          }
          if (store.error != null && all.isEmpty) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrandBar(),
              const Padding(padding: EdgeInsets.fromLTRB(28, 10, 28, 0), child: ScreenTitle('My library')),
              EmptyState(Icons.wifi_off, 'Can’t load your library', store.error!, action: PrimaryButton('Try again', height: 50, fontSize: 15, weight: FontWeight.w600, onTap: store.load)),
            ]);
          }
          if (all.isEmpty) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrandBar(),
              const Padding(padding: EdgeInsets.fromLTRB(28, 10, 28, 0), child: ScreenTitle('My library')),
              EmptyState(Icons.collections_bookmark_outlined, 'Your library is empty', 'Search the catalogue and add games you’ve played, are playing, or want to play.',
                  action: PrimaryButton('Discover games', height: 50, fontSize: 15, weight: FontWeight.w600, onTap: () => context.findAncestorStateOfType<_ShellState>()?.go(1))),
            ]);
          }
          return RefreshIndicator(
            color: C.lime,
            backgroundColor: C.card,
            onRefresh: store.load,
            child: CustomScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, slivers: [
              const SliverToBoxAdapter(child: BrandBar()),
              SliverToBoxAdapter(child: head),
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(Icons.search_off, 'No games match', 'Try a different search, status or category.',
                      action: OutlineBtn('Clear filters', onTap: () => setState(() { _q.clear(); f = null; horror = false; }))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 16, mainAxisExtent: posterH(context) + 54),
                    delegate: SliverChildBuilderDelegate(
                      childCount: list.length,
                      (_, k) {
                        final g = list[k];
                        return Entrance(
                          key: ValueKey(g.rawgId),
                          index: k,
                          child: GameTile(
                            coverUrl: g.coverUrl,
                            onTap: () => openGame(context, g, 'Library'),
                            details: [GameTitle(g.title), Align(alignment: Alignment.centerLeft, child: g.status == null ? const SizedBox(height: 20) : StatusTag(g.status!))],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ]),
          );
        },
      );
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverState();
}

class _DiscoverState extends State<DiscoverScreen> {
  final _q = TextEditingController();

  void resetSearch() {
    _t?.cancel();
    if (_q.text.isEmpty && term.isEmpty) return;
    _q.clear();
    term = '';
    go();
  }

  List<Game> res = [];
  bool loading = true;
  String? err;
  String term = '';
  DiscoverFilter filter = DiscoverFilter.all;
  Timer? _t;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    go();
  }

  @override
  void dispose() {
    _t?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> go() async {
    final my = ++_seq;
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final r = await Rawg.discover(term, filter);
      if (my != _seq) return;
      res = r;
    } catch (e) {
      if (my != _seq) return;
      err = friendly(e);
    }
    if (mounted) setState(() => loading = false);
  }

  void _search(String v) {
    _t?.cancel();
    final t = v.trim();
    if (t.isNotEmpty && t.length < 2) return;
    _t = Timer(Duration(milliseconds: t.isEmpty ? 0 : 450), () {
      term = t;
      go();
    });
  }

  Widget _tile(Game g) {
    final mine = store.byRawg(g.rawgId);
    final sub = [if (g.year != '—') g.year, if (g.genres.isNotEmpty) g.genres.take(2).join(' ')].join(' · ');
    return GameTile(
      coverUrl: g.coverUrl,
      gap: 4,
      onTap: () => openGame(context, mine ?? g, 'Discover'),
      details: [
        SizedBox(
          height: 20,
          child: Row(children: [
            Expanded(child: GameTitle(g.title)),
            const SizedBox(width: 4),
            Bounce(
              onTap: mine != null
                  ? null
                  : () async {
                      try {
                        await store.save(g.copyWith(status: GameStatus.wishlist));
                        if (mounted) toast(context, '${g.title} added to your library');
                      } catch (e) {
                        if (mounted) toast(context, friendly(e), error: true);
                      }
                    },
              child: SizedBox(width: 20, height: 20, child: Icon(mine != null ? Icons.check : Icons.add, size: 14, color: mine != null ? C.lime : C.ink2)),
            ),
          ]),
        ),
        SizedBox(height: 16, child: Text(sub.isEmpty ? 'Video game' : sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, color: C.muted, h: 16 / 11))),
      ],
    );
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (_, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BrandBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ScreenTitle('Discover'),
              const SizedBox(height: 16),
              SearchBox(_q, 'Search games', onChanged: _search, onSubmitted: (v) {
                _t?.cancel();
                term = v.trim();
                go();
              }),
              const SizedBox(height: 12),
              Row(children: [
                for (final f in DiscoverFilter.values) ...[
                  ChipPill(f.label, filter == f, () {
                    setState(() => filter = f);
                    go();
                  }),
                  const SizedBox(width: 8),
                ],
              ]),
            ]),
          ),
          Expanded(
            child: err != null && res.isEmpty
                ? SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                    child: EmptyState(Icons.wifi_off, 'Can’t reach the catalogue', err!, action: PrimaryButton('Try again', height: 50, fontSize: 15, weight: FontWeight.w600, onTap: go)))
                : loading && res.isEmpty
                    ? const SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, physics: NeverScrollableScrollPhysics(), child: SkeletonGrid(rows: 3))
                    : res.isEmpty
                        ? const SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, child: EmptyState(Icons.search_off, 'No games found', 'Try a different title or pick another filter.'))
                        : Column(children: [
                            if (Rawg.usingFallback)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                                child: Text('RAWG is down right now, so these results come from Steam (PC games).', style: ts(11, color: C.muted, h: 16 / 11)),
                              ),
                            if (loading) const Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: LinearProgressIndicator(minHeight: 2, color: C.lime, backgroundColor: C.line)),
                            Expanded(
                              child: GridView.builder(
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                                cacheExtent: 800,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 20, mainAxisExtent: posterH(context) + 48),
                                itemCount: res.length,
                                itemBuilder: (_, k) => Entrance(key: ValueKey(res[k].rawgId), index: k, child: _tile(res[k])),
                              ),
                            ),
                          ]),
          ),
        ]),
      );
}

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  final String backLabel;
  const GameDetailsScreen({super.key, required this.game, this.backLabel = 'Library'});
  @override
  State<GameDetailsScreen> createState() => _DetailsState();
}

class _DetailsState extends State<GameDetailsScreen> {
  late Game g = widget.game;
  late GameStatus status = g.status ?? GameStatus.wishlist;
  late bool horror = g.horror;
  late double? rating = g.rating;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if ((g.description ?? '').isEmpty) {
      Rawg.detail(g.rawgId).then((d) {
        if (mounted) setState(() => g = g.copyWith(description: d.description));
      }).catchError((_) {});
    }
  }

  Future<void> _do(Future<void> Function() f, String ok) async {
    setState(() => busy = true);
    try {
      await f();
      if (!mounted) return;
      toast(context, ok);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        toast(context, friendly(e), error: true);
        setState(() => busy = false);
      }
    }
  }

  Widget _option(GameStatus s) {
    final sel = status == s;
    return Bounce(
      onTap: busy ? null : () => setState(() => status = s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: sel ? C.limeDeep : C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? C.lime : C.line)),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? C.lime : C.muted, width: 1.5)),
            child: Center(child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: sel ? 8 : 0, height: sel ? 8 : 0, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle))),
          ),
          const SizedBox(width: 12),
          Text(s.label, style: ts(14, color: sel ? C.lime : C.ink, w: sel ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _toggle(bool on) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 26,
        decoration: BoxDecoration(color: on ? C.lime : C.bg, borderRadius: BorderRadius.circular(100), border: Border.all(color: on ? C.lime : C.line)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Container(width: 18, height: 18, decoration: BoxDecoration(color: on ? C.onLime : C.muted, shape: BoxShape.circle))),
        ),
      );

  Widget _stars() {
    final value = rating?.round() ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 28,
        child: Row(children: [
          Expanded(child: Text('My rating', style: ts(14, w: FontWeight.w500))),
          if (rating != null)
            Text.rich(TextSpan(children: [
              TextSpan(text: rating!.toStringAsFixed(rating! % 1 == 0 ? 0 : 1), style: ts(24, color: C.lime, w: FontWeight.w600, ls: -0.8)),
              TextSpan(text: ' / 10', style: ts(12, color: C.muted)),
            ]))
          else
            Text('Tap a star', style: ts(12, color: C.muted)),
        ]),
      ),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (_, box) {
        void drag(double dx) {
          final v = (dx / box.maxWidth * 10).ceil().clamp(1, 10).toDouble();
          if (v != rating) setState(() => rating = v);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: busy ? null : (d) => drag(d.localPosition.dx),
          child: Row(children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: busy ? null : () => setState(() => rating = rating == i.toDouble() ? null : i.toDouble()),
                  child: SizedBox(
                    height: 36,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, key: ValueKey('$i-${i <= value}'), size: 28, color: i <= value ? C.lime : C.muted),
                    ),
                  ),
                ),
              ),
          ]),
        );
      }),
    ]);
  }

  @override
  Widget build(BuildContext c) => Ambient(
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Bounce(
                  onTap: () => Navigator.pop(c),
                  child: SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        const SizedBox(width: 40, height: 44, child: Icon(Icons.arrow_back, size: 20, color: C.ink)),
                        const SizedBox(width: 4),
                        Text(widget.backLabel, style: ts(14, color: C.ink2)),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Entrance(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          SizedBox(width: 112, height: 168, child: Cover(g.coverUrl, px: 420, radius: 14)),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (g.saved) Text('IN YOUR COLLECTION', style: ts(9, color: C.lime, w: FontWeight.w600, ls: 1.1)),
                              if (g.saved) const SizedBox(height: 6),
                              Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(34, ls: -1.4, h: 38 / 34)),
                              if (g.year != '—') ...[const SizedBox(height: 6), Text(g.year, style: ts(13, color: C.ink2, h: 18 / 13))],
                              if (g.genres.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(g.genres.take(3).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, color: C.muted, h: 18 / 12)),
                              ],
                            ]),
                          ),
                        ]),
                        if ((g.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ExpandableText(g.description!, ts(13, color: C.ink2, h: 20 / 13)),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Entrance(
                      index: 1,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionLabel('Where are you at?'),
                        const SizedBox(height: 10),
                        for (final s in GameStatus.values) Padding(padding: EdgeInsets.only(bottom: s == GameStatus.values.last ? 0 : 6), child: _option(s)),
                        const SizedBox(height: 20),
                        Bounce(
                          onTap: busy ? null : () => setState(() => horror = !horror),
                          child: Container(
                            height: 72,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
                            child: Row(children: [
                              Expanded(
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Horror game', style: ts(14, w: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('Turn on to filter it as Horror in your library.', style: ts(11, color: C.muted, h: 15 / 11)),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              _toggle(horror),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _stars(),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Entrance(
                      index: 2,
                      child: Column(children: [
                        PrimaryButton(g.saved ? 'Update game' : 'Add to my stack', height: 50, fontSize: 15, weight: FontWeight.w600, busy: busy, onTap: () => _do(
                            () => store.save(g.copyWith(status: status, horror: horror, rating: rating, clearRating: rating == null)), g.saved ? 'Game updated' : 'Added to your stack')),
                        if (g.saved) ...[
                          const SizedBox(height: 8),
                          OutlineBtn('Remove from collection', color: C.ink2, height: 46, radius: 18, onTap: busy
                              ? null
                              : () async {
                                  if (await confirm(c, 'Remove game?', '“${g.title}” will be removed from your collection.', 'Remove', danger: true)) {
                                    _do(() => store.remove(g), 'Removed from collection');
                                  }
                                }),
                        ],
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse('https://rawg.io/'), mode: LaunchMode.externalApplication),
                          child: Text.rich(TextSpan(style: ts(10, color: C.muted, h: 18 / 10), children: [
                            const TextSpan(text: 'Game data by '),
                            TextSpan(text: 'RAWG', style: ts(10, color: C.muted, w: FontWeight.w600, h: 18 / 10)),
                            const TextSpan(text: ' · '),
                            TextSpan(text: 'rawg.io', style: ts(10, color: C.muted, h: 18 / 10).copyWith(decoration: TextDecoration.underline)),
                          ])),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

String initials(String n) => n.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

class Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final File? file;
  final double size, fontSize;
  const Avatar(this.name, {super.key, this.url, this.file, this.size = 68, this.fontSize = 23});
  @override
  Widget build(BuildContext c) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: C.limeDeep,
          border: Border.all(color: C.lime),
          image: file != null
              ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover)
              : (url != null ? DecorationImage(image: CachedNetworkImageProvider(url!, maxWidth: 300), fit: BoxFit.cover) : null),
        ),
        child: file == null && url == null ? Center(child: Text(initials(name), style: ts(fontSize, color: C.lime, w: FontWeight.w600, ls: -0.7))) : null,
      );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  Map<String, dynamic>? p;
  String? err;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await ProfileRepo.get();
      if (mounted) setState(() { p = r; err = null; });
    } catch (e) {
      if (mounted) setState(() => err = friendly(e));
    }
  }

  Widget _row(String l, int n) => SizedBox(height: 26, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: ts(13, w: FontWeight.w500)), Text('$n', style: ts(13, color: C.ink2, w: FontWeight.w600))]));
  Widget _div() => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: C.line));

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (_, __) {
          if (p == null) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrandBar(height: 52),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: const ScreenTitle('Profile')),
              if (err != null)
                EmptyState(Icons.wifi_off, 'Can’t load your profile', err!, action: PrimaryButton('Try again', height: 50, fontSize: 15, weight: FontWeight.w600, onTap: load))
              else
                const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator())),
            ]);
          }
          final a = store.games;
          return SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrandBar(height: 52),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Entrance(child: ScreenTitle('Profile')),
                  const SizedBox(height: 2),
                  Entrance(
                    index: 1,
                    child: SizedBox(
                      height: 80,
                      child: Row(children: [
                        Avatar(p!['nickname'], url: p!['avatar_url']),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p!['nickname'], maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(22, w: FontWeight.w600, ls: -0.6)),
                            const SizedBox(height: 6),
                            Text(p!['email'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, color: C.muted)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Entrance(
                    index: 2,
                    child: OutlineBtn('Edit profile', icon: Icons.edit_outlined, color: C.lime, background: C.card, height: 44, weight: FontWeight.w600, iconSize: 15,
                        onTap: () async {
                      await Navigator.push(c, slideRoute(EditProfileScreen(p!)));
                      load();
                    }),
                  ),
                  const SizedBox(height: 30),
                  Entrance(
                    index: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionLabel('My stats'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                        child: Column(children: [
                          _row('Total', a.length),
                          _div(),
                          _row('Played', countStatus(a, GameStatus.played)),
                          _div(),
                          _row('Playing', countStatus(a, GameStatus.playing)),
                          _div(),
                          _row('Horror games played', a.where((g) => g.horror && g.status == GameStatus.played).length),
                          _div(),
                          _row('Wishlist', countStatus(a, GameStatus.wishlist)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  Entrance(
                    index: 4,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionLabel('Account'),
                      const SizedBox(height: 12),
                      OutlineBtn('Log out', icon: Icons.logout, background: C.card, onTap: () async {
                        if (await confirm(c, 'Log out?', 'Your game collection stays safely in your account.', 'Log out')) await sb.auth.signOut();
                      }),
                      const SizedBox(height: 12),
                      Container(
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Deleting your account permanently removes your profile and game library.', style: ts(11, color: C.muted, h: 15 / 11)),
                          const SizedBox(height: 10),
                          OutlineBtn('Delete account', icon: Icons.delete_outline, color: C.danger, border: C.dangerLine, onTap: () async {
                            if (!await confirm(c, 'Delete your account?', 'This permanently removes your profile and every game in your library. This can’t be undone.', 'Delete', danger: true)) return;
                            try {
                              await ProfileRepo.deleteAccount();
                            } catch (e) {
                              if (mounted) toast(context, friendly(e), error: true);
                            }
                          }),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          );
        },
      );
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> p;
  const EditProfileScreen(this.p, {super.key});
  @override
  State<EditProfileScreen> createState() => _EditState();
}

class _EditState extends State<EditProfileScreen> {
  late final _n = TextEditingController(text: widget.p['nickname']);
  late final _e = TextEditingController(text: widget.p['email'] ?? '');
  File? photo;
  bool busy = false;

  @override
  void dispose() {
    _n.dispose();
    _e.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Ambient(
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Bounce(
                  onTap: () => Navigator.pop(c),
                  child: SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        const SizedBox(width: 40, height: 44, child: Icon(Icons.arrow_back, size: 20, color: C.ink)),
                        const SizedBox(width: 4),
                        Text('Profile', style: ts(14, color: C.ink2)),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Entrance(child: ScreenTitle('Edit profile')),
                    Entrance(
                      index: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Column(children: [
                            ValueListenableBuilder(valueListenable: _n, builder: (_, __, ___) => Avatar(_n.text, url: widget.p['avatar_url'], file: photo, size: 88, fontSize: 30)),
                            const SizedBox(height: 14),
                            Bounce(
                              onTap: busy
                                  ? null
                                  : () async {
                                      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                                      if (x != null) setState(() => photo = File(x.path));
                                    },
                              child: SizedBox(
                                height: 32,
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.photo_camera_outlined, size: 16, color: C.lime),
                                  const SizedBox(width: 8),
                                  Text('Change photo', style: ts(13, color: C.lime, w: FontWeight.w600)),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Entrance(index: 2, child: FormBox('Display name', 'Your nickname', _n, labelSize: 13, action: TextInputAction.done)),
                    const SizedBox(height: 24),
                    Entrance(index: 3, child: FormBox('Email', '', _e, labelSize: 13, readOnly: true)),
                    const SizedBox(height: 32),
                    Entrance(
                      index: 4,
                      child: PrimaryButton('Save changes', height: 54, fontSize: 15, weight: FontWeight.w600, busy: busy, onTap: () async {
                        final problem = validateNickname(_n.text);
                        if (problem != null) {
                          toast(context, problem, error: true);
                          return;
                        }
                        setState(() => busy = true);
                        try {
                          await ProfileRepo.save(_n.text.trim(), photo: photo);
                          if (!mounted) return;
                          toast(context, 'Profile updated');
                          Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            toast(context, friendly(e), error: true);
                            setState(() => busy = false);
                          }
                        }
                      }),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
