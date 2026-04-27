import 'dart:math';
import 'package:flutter/material.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double deltaX;
  final int curveCount;

  const ShakeWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.deltaX = 20,
    this.curveCount = 4,
  }) : super(key: key);

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    if (mounted) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue = sin(widget.curveCount * pi * _animation.value);
        return Transform.translate(
          offset: Offset(sineValue * widget.deltaX, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class FlashWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color flashColor;

  const FlashWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.flashColor = Colors.greenAccent,
  }) : super(key: key);

  @override
  FlashWidgetState createState() => FlashWidgetState();
}

class FlashWidgetState extends State<FlashWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.flashColor.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flash() {
    if (mounted) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  color: _colorAnimation.value,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
