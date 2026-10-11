import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

class AllmonitoringCard extends StatelessWidget {
  final String title;
  /// 고정 7개의 텍스트 데이터 (라벨: 값)
  final Map<String, String> fields;
  /// 하단 2개 버튼에 전달할 콜백 함수 (버튼 타입/식별자, 라벨)
  final Function(String actionType)? onControlAction;

  const AllmonitoringCard({
    super.key,
    required this.title,
    required this.fields,
    this.onControlAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isControl = onControlAction != null;
    final entries = fields.entries.toList();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isControl
              ? context.colors.primary.withValues(alpha: 0.18)
              : context.colors.outline,
        ),
        boxShadow: isControl ? context.colors.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 카드 타이틀 헤더
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (isControl) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '제어',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // 2. 내부 텍스트 7개 배치 (2줄/그리드 형태)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(7, (index) {
              final String label = index < entries.length ? entries[index].key : '-';
              final String value = index < entries.length ? entries[index].value : '-';

              return SizedBox(
                // 카드 너비 내부에서 약 절반씩 차지하도록 설정
                width: (MediaQuery.of(context).size.width / 4) - 24,
                child: _DisplayTile(label: label, value: value),
              );
            }),
          ),

          const SizedBox(height: 12),

          // 3. 하단 고정 2개 버튼 영역 (2줄 구조의 하단)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: isControl ? () => onControlAction!('ACTION_1') : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('설정 1', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isControl ? () => onControlAction!('ACTION_2') : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('시설로 이동', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 7개 읽기 전용 텍스트 필드를 나타내는 압축형 위젯
class _DisplayTile extends StatelessWidget {
  final String label;
  final String value;

  const _DisplayTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}