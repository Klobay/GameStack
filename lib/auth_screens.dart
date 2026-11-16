import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'services.dart';
import 'theme.dart';
import 'welcome_art.dart';
import 'widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeState();
}

class _WelcomeState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);

  @override
  void dispose() {
    float.dispose();
    super.dispose();
  }

  Widget _cover(Uint8List art, double cx, double cy, double w, double h, double deg, double s, double phase) {
    final shape = BorderRadius.circular(14);
    return Positioned(
      left: (cx - w / 2) * s,
      top: (cy - h / 2) * s,
      width: w * s,
      height: h * s,
      child: AnimatedBuilder(
        animation: float,
        builder: (_, child) => Transform.translate(offset: Offset(0, (float.value * 2 - 1) * 6 * phase), child: child),
        child: Transform.rotate(
          angle: deg * math.pi / 180,
          child: Container(
            decoration: BoxDecoration(borderRadius: shape, border: Border.all(color: C.line), boxShadow: const [BoxShadow(color: Color(0x70000000), blurRadius: 24, offset: Offset(0, 16))]),
            child: ClipRRect(
              borderRadius: shape,
              child: Stack(fit: StackFit.expand, children: [
                Image.memory(art, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, __, ___) => const ColoredBox(color: C.card)),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(0, -0.1), end: Alignment.bottomCenter, colors: [Color(0x00101211), Color(0xF2101211)])),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(double cx, double cy, double w, double h, double deg, double s, double phase, Widget child) => Positioned(
        left: (cx - w / 2) * s,
        top: (cy - h / 2) * s,
        width: w * s,
        height: h * s,
        child: AnimatedBuilder(
          animation: float,
          builder: (_, c) => Transform.translate(offset: Offset(0, (float.value * 2 - 1) * 5 * phase), child: c),
          child: Transform.rotate(angle: deg * math.pi / 180, child: Center(child: child)),
        ),
      );

  @override
  Widget build(BuildContext context) => Ambient(
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (_, box) {
                final s = box.maxWidth / 393;
                return SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const BrandBar(),
                      Entrance(
                        child: SizedBox(
                          height: 319 * s,
                          child: Stack(clipBehavior: Clip.none, children: [
                            Positioned.fill(child: CustomPaint(painter: _OrbitPainter(s))),
                            _cover(skyrimArt, 116.3, 151.3, 139, 201, -13, s, -1),
                            _cover(witcherArt, 280.6, 153.3, 132, 202, 13, s, 1.2),
                            _cover(rdr2Art, 199.9, 142.1, 175, 247, -4, s, 0.8),
                            _chip(
                                245.3,
                                34.7,
                                88.1,
                                35.4,
                                5,
                                s,
                                -1,
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                  decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(100)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.play_arrow, size: 11, color: C.onLime),
                                    const SizedBox(width: 6),
                                    Text('PLAYING', style: ts(10, color: C.onLime, w: FontWeight.w800, ls: 0.7)),
                                  ]),
                                )),
                            _chip(
                                92.5,
                                264.6,
                                125,
                                38.6,
                                -5,
                                s,
                                1,
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(100), border: Border.all(color: C.line)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.add, size: 12, color: C.ink),
                                    const SizedBox(width: 6),
                                    Text('WANT TO PLAY', style: ts(10, w: FontWeight.w600, ls: 0.6)),
                                  ]),
                                )),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 9, 28, 0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Entrance(index: 1, child: Text('DISCOVER · COLLECT · PLAY', style: ts(10, color: C.limeSoft, w: FontWeight.w600, ls: 1.9))),
                          const SizedBox(height: 15),
                          Entrance(index: 2, child: Text('Your games, all in one place.', style: ts(36, ls: -1.4, h: 40 / 36))),
                          const SizedBox(height: 15),
                          Entrance(
                              index: 3,
                              child: Text('Discover new games, build your library, and keep track of what you’ve played, what you’re playing, and what’s next.',
                                  style: ts(15, color: C.ink2, h: 24 / 15))),
                        ]),
                      ),
                      Entrance(
                        index: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                          child: Column(children: [
                            PrimaryButton('Get started', color: C.limeSoft, trailing: Icons.arrow_forward, onTap: () => Navigator.push(context, slideRoute(const SignupScreen()))),
                            const SizedBox(height: 10),
                            Bounce(
                              onTap: () => Navigator.push(context, slideRoute(const LoginScreen())),
                              child: SizedBox(height: 44, width: double.infinity, child: Center(child: Text('I already have an account', style: ts(13, color: C.ink2, w: FontWeight.w600)))),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 18, height: 4, decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(100))),
                          const SizedBox(width: 6),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: C.line, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: C.line, shape: BoxShape.circle)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _OrbitPainter extends CustomPainter {
  final double s;
  _OrbitPainter(this.s);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = (31 + 371.8 / 2) * s, cy = (-29.5 + 317.5 / 2) * s;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-10 * math.pi / 180);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 331 * s, height: 264 * s),
        Paint()
          ..color = C.lime.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter o) => o.s != s;
}

mixin AuthHelpers<T extends StatefulWidget> on State<T> {
  bool busy = false;
  Future<void> run(Future<void> Function() f, {String? ok}) async {
    setState(() => busy = true);
    try {
      await f();
      if (!mounted) return;
      if (ok != null) toast(context, ok);
    } catch (e) {
      if (mounted) toast(context, friendly(e), error: true);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> google() => run(() async {
        await sb.auth.signInWithOAuth(OAuthProvider.google, redirectTo: Env.redirect, authScreenLaunchMode: LaunchMode.externalApplication);
      });
  void done() => Navigator.of(context).popUntil((r) => r.isFirst);

  bool check(String? problem) {
    if (problem == null) return true;
    toast(context, problem, error: true);
    return false;
  }
}

class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget footer;
  const AuthScaffold(this.title, this.children, {super.key, this.subtitle, required this.footer});
  @override
  Widget build(BuildContext c) => Ambient(
        child: Scaffold(
          body: SafeArea(
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const BrandBar(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 60, 28, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Entrance(child: Text(title, style: ts(36, ls: -1.4, h: 40 / 36))),
                        if (subtitle != null) ...[const SizedBox(height: 10), Text(subtitle!, style: ts(14, color: C.muted, h: 22 / 14))],
                        const SizedBox(height: 36),
                        ...children,
                      ]),
                    ),
                  ]),
                ),
              ),
              footer,
            ]),
          ),
        ),
      );
}

class OrGoogle extends StatelessWidget {
  final VoidCallback? onTap;
  const OrGoogle(this.onTap, {super.key});
  @override
  Widget build(BuildContext c) => Column(children: [
        const SizedBox(height: 28),
        Row(children: [
          const Expanded(child: Divider(color: C.line, height: 1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: ts(11, color: C.muted, w: FontWeight.w500, ls: 1))),
          const Expanded(child: Divider(color: C.line, height: 1)),
        ]),
        const SizedBox(height: 24),
        OutlineBtn('Continue with Google', onTap: onTap, height: 56, radius: 18, fontSize: 15, weight: FontWeight.w600, leading: const GoogleMark()),
      ]);
}

Widget switchLink(String a, String b, VoidCallback f) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 28),
      child: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$a ', style: ts(13, color: C.ink2, h: 20 / 13)),
          GestureDetector(onTap: f, behavior: HitTestBehavior.opaque, child: Text(b, style: ts(13, color: C.limeSoft, w: FontWeight.w600, h: 20 / 13))),
          Text('.', style: ts(13, color: C.ink2, h: 20 / 13)),
        ]),
      ),
    );

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with AuthHelpers {
  final _e = TextEditingController(), _p = TextEditingController();
  @override
  void dispose() {
    _e.dispose();
    _p.dispose();
    super.dispose();
  }

  void _submit() {
    if (busy) return;
    if (!check(validateEmail(_e.text) ?? (_p.text.isEmpty ? 'Enter your password' : null))) return;
    run(() async {
      await sb.auth.signInWithPassword(email: _e.text.trim(), password: _p.text);
      done();
    });
  }

  @override
  Widget build(BuildContext c) => AuthScaffold(
        'Welcome back,',
        [
          Entrance(index: 1, child: FormBox('Email', 'Enter your email', _e, keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 22),
          Entrance(index: 2, child: FormBox('Password', 'Enter your password', _p, obscure: true, action: TextInputAction.done, onSubmitted: (_) => _submit())),
          SizedBox(
            height: 52,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(c, slideRoute(const RecoveryScreen())),
                  child: Text('Forgot password?', style: ts(13, color: C.limeSoft, w: FontWeight.w500))),
            ),
          ),
          const SizedBox(height: 8),
          Entrance(index: 3, child: PrimaryButton('Log in', color: C.limeSoft, busy: busy, onTap: _submit)),
          OrGoogle(busy ? null : google),
        ],
        footer: switchLink('Don’t have an account?', 'Sign up', () => Navigator.pushReplacement(c, slideRoute(const SignupScreen()))),
      );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupState();
}

class _SignupState extends State<SignupScreen> with AuthHelpers {
  final _n = TextEditingController(), _e = TextEditingController(), _p = TextEditingController();
  @override
  void dispose() {
    _n.dispose();
    _e.dispose();
    _p.dispose();
    super.dispose();
  }

  void _submit() {
    if (busy) return;
    if (!check(validateNickname(_n.text) ?? validateEmail(_e.text) ?? validatePassword(_p.text))) return;
    run(() async {
      final r = await sb.auth.signUp(email: _e.text.trim(), password: _p.text, data: {'nickname': _n.text.trim()}, emailRedirectTo: Env.redirect);
      if (r.session != null) {
        done();
      } else if (mounted) {
        toast(context, 'Check your email to confirm your account.');
      }
    });
  }

  @override
  Widget build(BuildContext c) => AuthScaffold(
        'Create account',
        [
          Entrance(index: 1, child: FormBox('Nickname', 'Choose a nickname', _n)),
          const SizedBox(height: 22),
          Entrance(index: 2, child: FormBox('Email', 'Enter your email', _e, keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 22),
          Entrance(index: 3, child: FormBox('Password', 'Create a password', _p, obscure: true, action: TextInputAction.done, onSubmitted: (_) => _submit())),
          const SizedBox(height: 28),
          Entrance(index: 4, child: PrimaryButton('Create account', color: C.limeSoft, busy: busy, onTap: _submit)),
          OrGoogle(busy ? null : google),
        ],
        footer: switchLink('Already have an account?', 'Log in', () => Navigator.pushReplacement(c, slideRoute(const LoginScreen()))),
      );
}

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryState();
}

class _RecoveryState extends State<RecoveryScreen> with AuthHelpers {
  final _e = TextEditingController();
  @override
  void dispose() {
    _e.dispose();
    super.dispose();
  }

  void _submit() {
    if (busy || !check(validateEmail(_e.text))) return;
    run(() => sb.auth.resetPasswordForEmail(_e.text.trim(), redirectTo: Env.redirect), ok: 'Recovery email sent. Check your inbox.');
  }

  @override
  Widget build(BuildContext c) => AuthScaffold(
        'Reset password',
        [
          Entrance(index: 1, child: FormBox('Email', 'Enter your email', _e, keyboardType: TextInputType.emailAddress, action: TextInputAction.done, onSubmitted: (_) => _submit())),
          const SizedBox(height: 28),
          Entrance(index: 2, child: PrimaryButton('Send recovery email', color: C.limeSoft, busy: busy, onTap: _submit)),
        ],
        subtitle: 'Enter your email and we’ll send you a recovery link.',
        footer: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 28),
          child: Center(child: GestureDetector(onTap: () => Navigator.pop(c), behavior: HitTestBehavior.opaque, child: Text('Back to log in', style: ts(13, color: C.limeSoft, w: FontWeight.w600)))),
        ),
      );
}
