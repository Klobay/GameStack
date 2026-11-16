import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamestack/auth_screens.dart';
import 'package:gamestack/models.dart';
import 'package:gamestack/theme.dart';
import 'package:gamestack/widgets.dart';

Widget host(Widget child) => MaterialApp(theme: buildTheme(), home: child);

void main() {
  testWidgets('welcome screen shows the headline and both actions', (tester) async {
    await tester.pumpWidget(host(const WelcomeScreen()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Your games, all in one place.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('login screen shows its fields and Google button', (tester) async {
    await tester.pumpWidget(host(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('empty email shows a validation message instead of calling the server', (tester) async {
    await tester.pumpWidget(host(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('status tag shows the right label', (tester) async {
    await tester.pumpWidget(host(const Scaffold(body: StatusTag(GameStatus.wishlist))));
    expect(find.text('Want to play'), findsOneWidget);
  });

  testWidgets('chip pill reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(Scaffold(body: ChipPill('Horror', false, () => taps++))));
    await tester.tap(find.text('Horror'));
    expect(taps, 1);
  });

  testWidgets('long descriptions are compact and expand on tap', (tester) async {
    final long = List.filled(60, 'word').join(' ');
    await tester.pumpWidget(host(Scaffold(body: SizedBox(width: 300, child: ExpandableText(long, ts(13))))));
    expect(find.text('Read more'), findsOneWidget);
    await tester.tap(find.text(long));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('short descriptions have no toggle', (tester) async {
    await tester.pumpWidget(host(Scaffold(body: SizedBox(width: 300, child: ExpandableText('Short.', ts(13))))));
    expect(find.text('Read more'), findsNothing);
  });
}
