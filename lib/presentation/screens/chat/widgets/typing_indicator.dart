import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color dotColor;

  const TypingIndicator({
    super.key,
    this.dotColor = Colors.grey,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // 각 점이 순차적으로 움직이도록 딜레이를 주고 시작합니다.
    _startAnimations();
  }

  void _startAnimations() async {
    for (var i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: indexToDelay(i)));
      if (mounted) _controllers[i].repeat(reverse: true);
    }
  }

  int indexToDelay(int index) => index * 200;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animations[index].value),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: widget.dotColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}