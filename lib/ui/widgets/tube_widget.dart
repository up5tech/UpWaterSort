import 'package:flutter/material.dart';

import 'tube_painter.dart';

/// Presentation-only tube: draws [layers], lifts when [selected] and flashes
/// a golden glow when it becomes [complete]. Taps are dispatched by the board.
class TubeWidget extends StatefulWidget {
  const TubeWidget({
    super.key,
    required this.index,
    required this.width,
    required this.height,
    required this.layers,
    required this.capacity,
    required this.selected,
    required this.complete,
    required this.lift,
    this.colorBlind = false,
    this.topLayerFraction = 1,
    this.extraLayerColor,
    this.extraLayerFraction = 0,
    this.hidden = false,
    this.onTap,
  });

  final int index;
  final double width;
  final double height;
  final List<int> layers;
  final int capacity;
  final bool selected;
  final bool complete;

  /// How far the tube rises when selected.
  final double lift;
  final bool colorBlind;
  final double topLayerFraction;
  final int? extraLayerColor;
  final double extraLayerFraction;

  /// The real tube is hidden while its flying copy is animating.
  final bool hidden;
  final VoidCallback? onTap;

  @override
  State<TubeWidget> createState() => _TubeWidgetState();
}

class _TubeWidgetState extends State<TubeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _wasComplete = false;

  @override
  void initState() {
    super.initState();
    // Tubes that are already complete on entry (e.g. resumed game) must not
    // flash; only a fresh completion does.
    _wasComplete = widget.complete;
  }

  @override
  void didUpdateWidget(TubeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.complete && !_wasComplete) {
      _glow.forward(from: 0);
    } else if (!widget.complete && _wasComplete) {
      _glow.value = 1;
    }
    _wasComplete = widget.complete;
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          widget.selected ? -widget.lift : 0,
          0,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Semantics(
            button: true,
            selected: widget.selected,
            label: 'Tube ${widget.index + 1}',
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, child) {
                  final glow = 1 - _glow.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        if (glow > 0)
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.65 * glow),
                            blurRadius: 22 * glow,
                            spreadRadius: 2 * glow,
                          ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: CustomPaint(
                  painter: TubePainter(
                    layers: widget.layers,
                    capacity: widget.capacity,
                    selected: widget.selected,
                    colorBlind: widget.colorBlind,
                    complete: widget.complete,
                    topLayerFraction: widget.topLayerFraction,
                    extraLayerColor: widget.extraLayerColor,
                    extraLayerFraction: widget.extraLayerFraction,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
