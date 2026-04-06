import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TypingMarkdown extends StatefulWidget {
  final String data;
  final VoidCallback onType;
  final VoidCallback onComplete;

  const TypingMarkdown({
    super.key, 
    required this.data, 
    required this.onType, 
    required this.onComplete,
  });

  @override
  State<TypingMarkdown> createState() => _TypingMarkdownState();
}

class _TypingMarkdownState extends State<TypingMarkdown> {
  String _displayContext = "";
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    // 💡 초고속 전략: 텍스트 길이에 따라 한 번에 뿜어내는 양을 조절
    // 500자 이상 장문일 경우 한 번에 8글자씩 출력 (매우 빠름)
    int step = (widget.data.length / 80).clamp(2, 8).toInt();
    
    // 주기는 15ms로 고정 (거의 실시간 전송 느낌)
    _timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (_currentIndex < widget.data.length) {
        if (mounted) {
          setState(() {
            _currentIndex += step;
            if (_currentIndex > widget.data.length) {
              _currentIndex = widget.data.length;
            }
            _displayContext = widget.data.substring(0, _currentIndex);
          });
          widget.onType(); // 스크롤 하단 이동
        }
      } else {
        _timer?.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayContext,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1A1919)),
      ),
    );
  }
}