import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';

class Bounce extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const Bounce({super.key, this.onTap, required this.child});
  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce> {
  bool down = false;
  void _set(bool v) {
    if (mounted && down != v) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: down ? 0.96 : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
      );
}

class Entrance extends StatefulWidget {
  final int index;
  final Widget child;
  const Entrance({super.key, this.index = 0, required this.child});
  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final int total = 420 + widget.index * 50;
  late final AnimationController c = AnimationController(vsync: this, duration: Duration(milliseconds: total));
  late final Animation<double> a = CurvedAnimation(parent: c, curve: Interval(widget.index * 50 / total, 1, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.index < 9) {
      c.forward();
    } else {
      c.value = 1;
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: a,
        child: widget.child,
        builder: (_, child) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, (1 - a.value) * 40), child: child)),
      );
}

class Ambient extends StatefulWidget {
  final bool top;
  final Widget child;
  const Ambient({super.key, this.top = false, required this.child});
  @override
  State<Ambient> createState() => _AmbientState();
}

class _AmbientState extends State<Ambient> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        child: RepaintBoundary(child: widget.child),
        builder: (_, child) => CustomPaint(painter: _GlowPainter(c.value, widget.top), child: child),
      );
}

class _GlowPainter extends CustomPainter {
  final double t;
  final bool top;
  _GlowPainter(this.t, this.top);

  void glow(Canvas canvas, Size s, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & s, paint);
  }

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = C.bg);
    final w = s.width, h = s.height;
    glow(canvas, s, Offset(w * ((top ? 0.35 : 0.36) + 0.03 * t), h * ((top ? 0.17 : 0.365) + 0.015 * t)), w * 0.52, C.lime.withValues(alpha: 0.10));
    glow(canvas, s, Offset(w * (0.8 - 0.03 * t), h * ((top ? 0.36 : 0.55) - 0.015 * t)), w * 0.5, C.teal.withValues(alpha: 0.085));
    glow(canvas, s, Offset(w * 0.5, h * 1.01), w * 0.7, C.lime.withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(_GlowPainter o) => o.t != t || o.top != top;
}

class StackMark extends StatelessWidget {
  final double width, height;
  const StackMark({super.key, this.width = 25, this.height = 28});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, height), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    void layer(double top, double alpha) {
      final p = Path()
        ..moveTo(w / 2, top)
        ..lineTo(w - 1, top + h * 0.18)
        ..lineTo(w / 2, top + h * 0.36)
        ..lineTo(1, top + h * 0.18)
        ..close();
      canvas.drawPath(
          p,
          Paint()
            ..color = C.lime.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round);
    }

    layer(h * 0.56, 0.45);
    layer(h * 0.28, 0.75);
    layer(0, 1);
  }

  @override
  bool shouldRepaint(_MarkPainter o) => false;
}

class BrandBar extends StatelessWidget {
  final double height;
  const BrandBar({super.key, this.height = 64});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(children: [const StackMark(), const SizedBox(width: 10), Text('Game Stack', style: ts(19, ls: -0.6))]),
        ),
      );
}

class ScreenTitle extends StatelessWidget {
  final String text;
  const ScreenTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(height: 44, child: Align(alignment: Alignment.centerLeft, child: Text(text, maxLines: 1, style: ts(34, ls: -1.4))));
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: ts(10, color: C.muted, w: FontWeight.w600, ls: 1.5, h: 1.4));
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final Color color;
  final double height, fontSize;
  final FontWeight weight;
  final IconData? trailing;
  const PrimaryButton(this.label,
      {super.key, this.onTap, this.busy = false, this.color = C.lime, this.height = 56, this.fontSize = 16, this.weight = FontWeight.w700, this.trailing});

  @override
  Widget build(BuildContext context) => Bounce(
        onTap: busy ? null : onTap,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
          child: Stack(alignment: Alignment.center, children: [
            if (busy)
              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: C.onLime))
            else
              Text(label, style: ts(fontSize, color: C.onLime, w: weight)),
            if (trailing != null && !busy) Positioned(right: 21, child: Icon(trailing, size: 19, color: C.onLime)),
          ]),
        ),
      );
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading;
  final Color color, border, background;
  final double height, radius, fontSize, iconSize;
  final FontWeight weight;
  const OutlineBtn(this.label,
      {super.key,
      this.onTap,
      this.icon,
      this.leading,
      this.color = C.ink,
      this.border = C.line,
      this.background = Colors.transparent,
      this.height = 48,
      this.radius = 14,
      this.fontSize = 14,
      this.iconSize = 17,
      this.weight = FontWeight.w500});

  @override
  Widget build(BuildContext context) => Bounce(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius), border: Border.all(color: border)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              if (icon != null) ...[Icon(icon, size: iconSize, color: color), const SizedBox(width: 8)],
              Text(label, style: ts(fontSize, color: color, w: weight)),
            ]),
          ),
        ),
      );
}

class FormBox extends StatefulWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool obscure, readOnly;
  final TextInputType? keyboardType;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final double labelSize;
  const FormBox(this.label, this.hint, this.controller,
      {super.key, this.obscure = false, this.readOnly = false, this.keyboardType, this.action = TextInputAction.next, this.onSubmitted, this.labelSize = 14});
  @override
  State<FormBox> createState() => _FormBoxState();
}

class _FormBoxState extends State<FormBox> {
  final focus = FocusNode();
  bool focused = false;
  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() => focused = focus.hasFocus));
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label, style: ts(widget.labelSize, w: FontWeight.w500)),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: focused ? C.lime : C.line)),
          child: TextField(
            controller: widget.controller,
            focusNode: focus,
            obscureText: widget.obscure,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            textInputAction: widget.action,
            onSubmitted: (v) {
              if (widget.action == TextInputAction.done) focus.unfocus();
              widget.onSubmitted?.call(v);
            },
            cursorColor: C.lime,
            style: ts(15),
            decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: ts(15, color: C.muted)),
          ),
        ),
      ]);
}

class SearchBox extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged, onSubmitted;
  const SearchBox(this.controller, this.hint, {super.key, this.onChanged, this.onSubmitted});
  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final focus = FocusNode();
  bool focused = false;
  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() => focused = focus.hasFocus));
    widget.controller.addListener(_text);
  }

  void _text() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_text);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: focused ? C.lime : C.line)),
        child: Row(children: [
          const Icon(Icons.search, size: 18, color: C.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: focus,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: (v) {
                focus.unfocus();
                widget.onSubmitted?.call(v);
              },
              cursorColor: C.lime,
              style: ts(14),
              decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: ts(14, color: C.muted)),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.controller.clear();
                widget.onChanged?.call('');
              },
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 18, color: C.muted)),
            ),
        ]),
      );
}

class ChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChipPill(this.label, this.selected, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Bounce(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? C.lime : C.card, borderRadius: BorderRadius.circular(100), border: Border.all(color: selected ? C.lime : C.line)),
          child: Text(label, style: ts(12, color: selected ? C.onLime : C.ink2, w: FontWeight.w600)),
        ),
      );
}

class StatusTag extends StatelessWidget {
  final GameStatus s;
  const StatusTag(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final playing = s == GameStatus.playing;
    final icon = switch (s) {
      GameStatus.playing => Icons.play_arrow_outlined,
      GameStatus.played => Icons.check,
      GameStatus.wishlist => Icons.bookmark_border,
    };
    final label = switch (s) {
      GameStatus.playing => 'Playing',
      GameStatus.played => 'Played',
      GameStatus.wishlist => 'Want to play',
    };
    final color = playing ? C.lime : C.ink2;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(color: playing ? C.limeDeep : C.card, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: ts(10, color: color, w: FontWeight.w600)),
      ]),
    );
  }
}

String sized(String url, int px) {
  if (!url.contains('media.rawg.io/media/') || url.contains('/resize/') || url.contains('/crop/')) return url;
  final w = px <= 200 ? 200 : (px <= 420 ? 420 : 640);
  return url.replaceFirst('/media/', '/media/resize/$w/-/');
}

class Cover extends StatelessWidget {
  final String? url;
  final double radius;
  final int px;
  const Cover(this.url, {super.key, this.radius = 12, this.px = 420});
  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(color: C.card, child: Center(child: Icon(Icons.videogame_asset_outlined, color: C.muted, size: 30)));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: sized(url!, px),
              fit: BoxFit.cover,
              memCacheWidth: px,
              fadeInDuration: const Duration(milliseconds: 350),
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder),
    );
  }
}

class GameTile extends StatelessWidget {
  final String? coverUrl;
  final VoidCallback onTap;
  final double gap;
  final List<Widget> details;
  const GameTile({super.key, required this.coverUrl, required this.onTap, this.gap = 6, required this.details});
  @override
  Widget build(BuildContext context) => Bounce(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 2 / 3, child: Cover(coverUrl, radius: 14)),
          const SizedBox(height: 8),
          for (var i = 0; i < details.length; i++) ...[if (i > 0) SizedBox(height: gap), details[i]],
        ]),
      );
}

class GameTitle extends StatelessWidget {
  final String text;
  const GameTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, w: FontWeight.w600, ls: -0.3, h: 20 / 15));
}

class Shimmer extends StatefulWidget {
  final double? width, height;
  final double radius;
  const Shimmer({super.key, this.width, this.height, this.radius = 12});
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _SlideGradient extends GradientTransform {
  final double p;
  const _SlideGradient(this.p);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * p, 0, 0);
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(colors: const [C.card, Color(0xFF283029), C.card], stops: const [0.25, 0.5, 0.75], transform: _SlideGradient(-1 + 2 * c.value)),
          ),
        ),
      );
}

class SkeletonGrid extends StatelessWidget {
  final int rows;
  const SkeletonGrid({super.key, this.rows = 2});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                for (var k = 0; k < 2; k++) ...[
                  if (k == 1) const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const AspectRatio(aspectRatio: 2 / 3, child: Shimmer(radius: 14)),
                      const SizedBox(height: 8),
                      const Shimmer(width: 96, height: 14, radius: 5),
                      const SizedBox(height: 6),
                      const Shimmer(width: 60, height: 12, radius: 5),
                    ]),
                  ),
                ],
              ]),
            ),
        ]),
      );
}

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title, detail;
  final Widget? action;
  const EmptyState(this.icon, this.title, this.detail, {super.key, this.action});
  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Entrance(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: C.limeDeep, shape: BoxShape.circle),
                child: Icon(widget.icon, size: 32, color: C.lime),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title, textAlign: TextAlign.center, style: ts(20, w: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(widget.detail, textAlign: TextAlign.center, style: ts(14, color: C.muted, h: 22 / 14)),
            if (widget.action != null) ...[const SizedBox(height: 20), widget.action!],
          ]),
        ),
      );
}

enum NavKind { library, discover, profile }

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const BottomNav(this.index, this.onSelect, {super.key});
  @override
  Widget build(BuildContext context) {
    const items = [(NavKind.library, 'Library'), (NavKind.discover, 'Discover'), (NavKind.profile, 'Profile')];
    return Container(
      decoration: const BoxDecoration(color: C.bg, border: Border(top: BorderSide(color: C.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Bounce(
                    onTap: () => onSelect(i),
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: index == i ? C.lime : C.muted),
                      duration: const Duration(milliseconds: 220),
                      builder: (_, tint, __) => Column(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 52,
                          height: 28,
                          decoration: BoxDecoration(color: index == i ? C.limeDeep : Colors.transparent, borderRadius: BorderRadius.circular(100)),
                          child: Center(child: CustomPaint(size: const Size(21, 21), painter: NavGlyph(items[i].$1, tint ?? C.muted))),
                        ),
                        const SizedBox(height: 4),
                        Text(items[i].$2, style: ts(11, color: tint ?? C.muted, w: index == i ? FontWeight.w600 : FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class NavGlyph extends CustomPainter {
  final NavKind kind;
  final Color color;
  NavGlyph(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset o(double x, double y) => Offset(x * k, y * k);
    switch (kind) {
      case NavKind.library:
        canvas.drawLine(o(16, 6), o(20, 20), p);
        canvas.drawLine(o(12, 6), o(12, 20), p);
        canvas.drawLine(o(8, 8), o(8, 20), p);
        canvas.drawLine(o(4, 4), o(4, 20), p);
      case NavKind.discover:
        canvas.drawCircle(o(12, 12), 10 * k, p);
        final needle = Path()
          ..moveTo(16.24 * k, 7.76 * k)
          ..lineTo(14.12 * k, 14.12 * k)
          ..lineTo(7.76 * k, 16.24 * k)
          ..lineTo(9.88 * k, 9.88 * k)
          ..close();
        canvas.drawPath(needle, p);
      case NavKind.profile:
        canvas.drawCircle(o(12, 8), 5 * k, p);
        canvas.drawArc(Rect.fromLTWH(4 * k, 13 * k, 16 * k, 16 * k), math.pi, math.pi, false, p);
    }
  }

  @override
  bool shouldRepaint(NavGlyph o) => o.kind != kind || o.color != color;
}

class GoogleMark extends StatelessWidget {
  final double size;
  const GoogleMark({super.key, this.size = 20});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stroke = s.width * 0.19;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s.width - stroke, s.height - stroke);
    Paint paint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double rad(double d) => d * math.pi / 180;
    canvas.drawArc(rect, rad(135), rad(90), false, paint(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, rad(225), rad(80), false, paint(const Color(0xFFEA4335)));
    canvas.drawArc(rect, rad(45), rad(90), false, paint(const Color(0xFF34A853)));
    canvas.drawArc(rect, rad(-30), rad(75), false, paint(const Color(0xFF4285F4)));
    canvas.drawLine(Offset(s.width / 2, s.height / 2), Offset(s.width - stroke / 2, s.height / 2), paint(const Color(0xFF4285F4)));
  }

  @override
  bool shouldRepaint(_GooglePainter o) => false;
}

Route<T> slideRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: c, child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(c), child: child));
      },
    );

void toast(BuildContext c, String m, {bool error = false}) => ScaffoldMessenger.of(c)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(m, style: ts(14, color: error ? C.danger : C.ink))));

Future<bool> confirm(BuildContext c, String title, String body, String action, {bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: c,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Cancel', style: ts(14, color: C.ink2, w: FontWeight.w600))),
        TextButton(onPressed: () => Navigator.pop(d, true), child: Text(action, style: ts(14, color: danger ? C.danger : C.lime, w: FontWeight.w700))),
      ],
    ),
  );
  return ok == true;
}

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int lines;
  const ExpandableText(this.text, this.style, {super.key, this.lines = 2});
  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool open = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, box) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            maxLines: widget.lines,
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: box.maxWidth);
          final overflows = painter.didExceedMaxLines;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: overflows ? () => setState(() => open = !open) : null,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.text, maxLines: open ? null : widget.lines, overflow: open ? TextOverflow.visible : TextOverflow.ellipsis, style: widget.style),
                if (overflows) Padding(padding: const EdgeInsets.only(top: 6), child: Text(open ? 'Show less' : 'Read more', style: ts(12, color: C.lime, w: FontWeight.w600))),
              ]),
            ),
          );
        },
      );
}
