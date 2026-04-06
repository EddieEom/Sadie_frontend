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
    // 데이터가 비어있을 경우 바로 완료 처리
    if (widget.data.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
    } else {
      _startTyping();
    }
  }

  void _startTyping() {
    // 텍스트 길이에 따라 한 번에 추가될 글자 수 계산 (최소 2자, 최대 8자)
    final int step = (widget.data.length / 80).clamp(2, 8).toInt();
    
    _timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentIndex += step;
        if (_currentIndex >= widget.data.length) {
          _currentIndex = widget.data.length;
          _displayContext = widget.data;
          timer.cancel();
          widget.onComplete();
        } else {
          _displayContext = widget.data.substring(0, _currentIndex);
        }
      });
      
      widget.onType(); // 메시지가 길어질 때 리스트를 아래로 밀어줌
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
        p: const TextStyle(
          fontSize: 15, 
          height: 1.5, 
          color: Color(0xFF1A1919),
        ),
      ),
    );
  }
}