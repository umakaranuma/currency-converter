import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A rounded placeholder block that gently pulses between two theme skeleton
/// colours. Used to sketch the result rows while the first fetch is in flight
/// so the screen has shape instead of a bare spinner (features.md F5).
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.skeletonBase,
              colors.skeletonHighlight,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
