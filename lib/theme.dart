import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class C {
  static const bg = Color(0xFF101211);
  static const card = Color(0xFF1C201D);
  static const line = Color(0xFF343B34);
  static const ink = Color(0xFFF3F5ED);
  static const ink2 = Color(0xFFD7DBD4);
  static const muted = Color(0xFF929A90);
  static const lime = Color(0xFFB9F35A);
  static const limeSoft = Color(0xFFC4F568);
  static const limeDeep = Color(0xFF26351C);
  static const onLime = Color(0xFF18210F);
  static const teal = Color(0xFF2DD4BF);
  static const danger = Color(0xFFF08080);
  static const dangerLine = Color(0xFF9E4C4C);
}

TextStyle ts(double size, {Color color = C.ink, FontWeight w = FontWeight.w400, double? ls, double? h}) =>
    TextStyle(fontFamily: 'Inter', fontSize: size, color: color, fontWeight: w, letterSpacing: ls, height: h);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(primary: C.lime, onPrimary: C.onLime, secondary: C.lime, surface: C.bg, error: C.danger),
  );
  return base.copyWith(
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.lime, selectionColor: Color(0x55B9F35A), selectionHandleColor: C.lime),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.lime, linearTrackColor: C.line),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.card,
      contentTextStyle: ts(14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: ts(18, w: FontWeight.w600),
      contentTextStyle: ts(14, color: C.muted, h: 1.5),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: C.lime, textStyle: ts(14, w: FontWeight.w600))),
  );
}

const overlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: C.bg,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: Colors.transparent,
);
