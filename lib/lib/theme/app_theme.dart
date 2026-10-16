import 'package:flutter/material.dart';

class EduColors extends ThemeExtension<EduColors> {
  final Color ink, onInk, paper, card, chalk, marigold, charcoal, slate, rule, danger;
  const EduColors({
    required this.ink, required this.onInk, required this.paper, required this.card,
    required this.chalk, required this.marigold, required this.charcoal,
    required this.slate, required this.rule, required this.danger,
  });

  @override
  EduColors copyWith() => this;
  @override
  EduColors lerp(ThemeExtension<EduColors>? other, double t) => this;

  static const light = EduColors(
    ink: Color(0xFF1E2A44), onInk: Colors.white, paper: Color(0xFFEEF0EA),
    card: Colors.white, chalk: Color(0xFF2F6F4E), marigold: Color(0xFFE2963A),
    charcoal: Color(0xFF23262B), slate: Color(0xFF63697A), rule: Color(0xFFDEDBCF),
    danger: Color(0xFFC1442E),
  );
  static const dark = EduColors(
    ink: Color(0xFF7FD1AE), onInk: Color(0xFF0F231B), paper: Color(0xFF14161B),
    card: Color(0xFF1D2027), chalk: Color(0xFF4FB584), marigold: Color(0xFFE2A85C),
    charcoal: Color(0xFFECE9E2), slate: Color(0xFF9297A3), rule: Color(0xFF2C2F37),
    danger: Color(0xFFE2665A),
  );
  static const girly = EduColors(
    ink: Color(0xFFC2185B), onInk: Colors.white, paper: Color(0xFFFFF0F5),
    card: Colors.white, chalk: Color(0xFFE85D9E), marigold: Color(0xFFF2A6C4),
    charcoal: Color(0xFF6B2C55), slate: Color(0xFFB77A9A), rule: Color(0xFFF7D9E8),
    danger: Color(0xFFD6336C),
  );
}

extension EduContext on BuildContext {
  EduColors get edu => Theme.of(this).extension<EduColors>()!;
}

/// 'light', 'dark' or 'girly'. Change .value to switch the whole app.
final ValueNotifier<String> themeNotifier = ValueNotifier('light');

ThemeData buildTheme(String key) {
  final c = key == 'dark' ? EduColors.dark : key == 'girly' ? EduColors.girly : EduColors.light;
  final b = key == 'dark' ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme.fromSeed(seedColor: c.ink, brightness: b)
        .copyWith(primary: c.ink, onPrimary: c.onInk, surface: c.card),
    textTheme: ThemeData(brightness: b).textTheme
        .apply(bodyColor: c.charcoal, displayColor: c.charcoal),
    extensions: [c],
  );
}