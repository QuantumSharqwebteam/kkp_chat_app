import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Wraps a message item with a horizontal swipe gesture.
/// Swiping right past [_threshold] pixels fires [onReply] and snaps back.
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const SwipeToReply({super.key, required this.child, required this.onReply});

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap;
  Animation<double>? _snapAnim;
  double _dragX = 0;
  static const double _threshold = 60;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (d.delta.dx > 0) {
      setState(() => _dragX = min(_dragX + d.delta.dx, _threshold * 1.1));
    }
  }

  void _resetDrag() {
    final start = _dragX;
    _snapAnim = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOut),
    )..addListener(() => setState(() => _dragX = _snapAnim!.value));
    _snap
      ..reset()
      ..forward();
  }

  void _onEnd(DragEndDetails _) {
    if (_dragX >= _threshold) widget.onReply();
    _resetDrag();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragX / _threshold).clamp(0.0, 1.0);
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.start,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: _resetDrag,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: widget.child,
          ),
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: progress,
              child: const Center(
                child: Icon(
                  Icons.reply_rounded,
                  color: Color(0xFF6B7AED),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
