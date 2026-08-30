import 'package:flutter/material.dart';

/// Semantic colours that Material's [ColorScheme] does not model: the
/// success / warning / info triads used by the status banner and result states,
/// plus the brand gradient behind the header.
///
/// Registered as a [ThemeExtension] so widgets read them with
/// `Theme.of(context).extension<AppColors>()!` and they switch automatically
/// with light / dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onGradient,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Header gradient stops and the colour of content painted on top of it.
  final Color gradientStart;
  final Color gradientEnd;
  final Color onGradient;

  /// Loading-skeleton shimmer colours.
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const AppColors light = AppColors(
    success: Color(0xFF12A150),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCF3E4),
    onSuccessContainer: Color(0xFF0A3D22),
    warning: Color(0xFFF5A524),
    onWarning: Color(0xFF3A2A06),
    warningContainer: Color(0xFFFDF0DA),
    onWarningContainer: Color(0xFF5A3B0B),
    info: Color(0xFF3B82F6),
    infoContainer: Color(0xFFE3EEFF),
    onInfoContainer: Color(0xFF10336E),
    gradientStart: Color(0xFF4F6CF7),
    gradientEnd: Color(0xFF7C5CFC),
    onGradient: Color(0xFFFFFFFF),
    skeletonBase: Color(0xFFE8ECF4),
    skeletonHighlight: Color(0xFFF4F6FB),
  );

  static const AppColors dark = AppColors(
    success: Color(0xFF4ED88A),
    onSuccess: Color(0xFF06301B),
    successContainer: Color(0xFF12502F),
    onSuccessContainer: Color(0xFFC7F5D9),
    warning: Color(0xFFFFC24B),
    onWarning: Color(0xFF3A2A06),
    warningContainer: Color(0xFF5A3E11),
    onWarningContainer: Color(0xFFFFE9C2),
    info: Color(0xFF7FB0FF),
    infoContainer: Color(0xFF1E3A63),
    onInfoContainer: Color(0xFFD6E6FF),
    gradientStart: Color(0xFF3B50C9),
    gradientEnd: Color(0xFF5B3FC9),
    onGradient: Color(0xFFF3F5FF),
    skeletonBase: Color(0xFF1E232D),
    skeletonHighlight: Color(0xFF262C38),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? gradientStart,
    Color? gradientEnd,
    Color? onGradient,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      onGradient: onGradient ?? this.onGradient,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      onGradient: Color.lerp(onGradient, other.onGradient, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}

/// Ergonomic accessor: `context.appColors.success`.
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
