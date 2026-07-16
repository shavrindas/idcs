import 'package:flutter/material.dart';

/// Box #1, #2: 페이지 이동 박스
class NavigationBox extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const NavigationBox({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 컴포넌트 구분을 위한 가장 기본적인 검은색/회색 선만 적용
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: onPressed,
            child: const Text('버튼(이동)'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
    );
  }
}