import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFAF8F5);
  static const terracotta = Color(0xFFA23F23);
  static const ink = Color(0xFF29231F);
  static const muted = Color(0xFF75635B);
  static const surface = Color(0xFFF3F0EC);
  static const sage = Color(0xFF456B5C);
  // Existing buyer-home palette, shared by promotional components.
  static const warmBrown = Color(0xFF70452F);
  static const heroCream = Color(0xFFF2E3D5);
  static const trustBrown = Color(0xFF493B30);
  static Color get promoTint => Color.lerp(background, warmBrown, .09)!;
  static Color get sageTint => Color.lerp(background, sage, .12)!;
}
