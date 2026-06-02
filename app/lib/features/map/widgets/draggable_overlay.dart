import 'package:flutter/material.dart';

//* Draggable floating overlay: snap-to-corner (pills) or clamped free placement
class DraggableOverlay extends StatefulWidget {
  final Widget child;
  final bool snapToCorner;
  final Offset Function(Size screen, EdgeInsets padding) defaultOffset;
  //* Top inset so it can't be dragged under the AppBar
  final double topReserved;
  //* Bottom inset so it can't be dragged under the tab bar
  final double bottomReserved;

  const DraggableOverlay({
    super.key,
    required this.child,
    required this.snapToCorner,
    required this.defaultOffset,
    this.topReserved = 0,
    this.bottomReserved = 0,
  });

  @override
  State<DraggableOverlay> createState() => DraggableOverlayState();
}

class DraggableOverlayState extends State<DraggableOverlay> {
  //* Min drag (px) to treat as directional; smaller jitter snaps to nearest edge
  static const _dragSnapThreshold = 4.0;

  Offset? _offset;
  bool _animating = false;
  Offset? _dragStart;
  ({double x, double y})? _pendingSnapHint;
  final _innerKey = GlobalKey();

  //* Capture the current corner side before the child shrinks (call pre-setState)
  void recordSnapSide() {
    final offset = _offset;
    if (offset == null) return;
    final box = _innerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final screen = MediaQuery.of(context).size;
    _pendingSnapHint = (
      x: (offset.dx + size.width / 2) < screen.width / 2 ? -1.0 : 1.0,
      y: (offset.dy + size.height / 2) < screen.height / 2 ? -1.0 : 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant DraggableOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapToCorner != widget.snapToCorner) _settle();
  }

  //* Animate to the resting position (snap corner or clamp) after a mode change
  void _settle() {
    final hint = _pendingSnapHint;
    _pendingSnapHint = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _innerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final size = box.size;
      final screen = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final minY = padding.top + widget.topReserved + 8;
      final maxX = screen.width - size.width - 16;
      final maxY = screen.height -
          size.height -
          padding.bottom -
          widget.bottomReserved -
          16;
      final cur = _offset ?? Offset(16, minY);

      final Offset target;
      if (widget.snapToCorner) {
        final double targetX;
        final double targetY;
        if (hint != null) {
          targetX = hint.x < 0 ? 16.0 : maxX;
          targetY = hint.y < 0 ? minY : maxY;
        } else {
          final centerX = cur.dx + size.width / 2;
          final centerY = cur.dy + size.height / 2;
          targetX = centerX < screen.width / 2 ? 16.0 : maxX;
          targetY = centerY < screen.height / 2 ? minY : maxY;
        }
        target = Offset(targetX, targetY);
      } else {
        target = Offset(
          cur.dx.clamp(16.0, maxX).toDouble(),
          cur.dy.clamp(minY, maxY).toDouble(),
        );
      }
      if (target == cur) return;
      setState(() {
        _offset = target;
        _animating = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final offset = _offset ?? widget.defaultOffset(screen, padding);
    if (_offset == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _offset = offset;
          _animating = false;
        });
      });
    }
    final minY = padding.top + widget.topReserved + 8;

    return AnimatedPositioned(
      duration: _animating
          ? const Duration(milliseconds: 280)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanStart: (_) {
          _dragStart = _offset ?? offset;
          if (_animating) {
            setState(() {
              _offset = _dragStart;
              _animating = false;
            });
          }
        },
        onPanUpdate: (d) {
          final cur = _offset ?? offset;
          setState(() {
            _offset = cur + d.delta;
            _animating = false;
          });
        },
        onPanEnd: (_) {
          final cur = _offset ?? offset;
          final start = _dragStart ?? cur;
          _dragStart = null;
          final box = _innerKey.currentContext?.findRenderObject() as RenderBox?;
          final size = box?.size ?? Size.zero;
          final maxX = screen.width - size.width - 16;
          final maxY = screen.height -
              size.height -
              padding.bottom -
              widget.bottomReserved -
              16;
          final dx = cur.dx - start.dx;
          final dy = cur.dy - start.dy;

          double snappedX;
          if (dx.abs() < _dragSnapThreshold) {
            final centerX = cur.dx + size.width / 2;
            snappedX = centerX < screen.width / 2 ? 16.0 : maxX;
          } else {
            snappedX = dx < 0 ? 16.0 : maxX;
          }

          double snappedY;
          if (dy.abs() < _dragSnapThreshold) {
            final centerY = cur.dy + size.height / 2;
            snappedY = centerY < screen.height / 2 ? minY : maxY;
          } else {
            snappedY = dy < 0 ? minY : maxY;
          }

          setState(() {
            _offset = Offset(snappedX, snappedY);
            _animating = true;
          });
        },
        child: KeyedSubtree(key: _innerKey, child: widget.child),
      ),
    );
  }
}
