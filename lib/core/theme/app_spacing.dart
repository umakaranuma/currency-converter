/// Layout primitives for the design system: one spacing scale and one radius
/// scale, used everywhere instead of magic numbers so rhythm stays consistent.
library;

import 'package:flutter/widgets.dart';

/// 4-point spacing scale. Reach for these instead of raw `EdgeInsets` numbers.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard screen gutter.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
}

/// Corner-radius scale. Cards use [lg], pills use [pill].
abstract final class AppRadius {
  static const Radius sm = Radius.circular(10);
  static const Radius md = Radius.circular(14);
  static const Radius lg = Radius.circular(20);
  static const Radius xl = Radius.circular(28);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius allSm = BorderRadius.all(sm);
  static const BorderRadius allMd = BorderRadius.all(md);
  static const BorderRadius allLg = BorderRadius.all(lg);
  static const BorderRadius allXl = BorderRadius.all(xl);
  static const BorderRadius allPill = BorderRadius.all(pill);
}
