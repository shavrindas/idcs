import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #2: 통합 시설 박스
class IntegratedFacilityBox extends StatelessWidget {
  final List<dynamic> facilities;
  final Function(int) onFacilityPressed;
  final String label;
  final String emptyMessage;

  const IntegratedFacilityBox({
    super.key,
    required this.facilities,
    required this.onFacilityPressed,
    this.label = '내 시설',
    this.emptyMessage = '조회할 수 있는 시설이 없습니다.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // An empty label means the screen already names this section in its app bar.
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
        ],

        if (facilities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.outline),
            ),
            child: Column(
              children: [
                Icon(Icons.domain_disabled_outlined, color: context.colors.textSecondary.withValues(alpha: 0.6), size: 28),
                const SizedBox(height: 8),
                Text(emptyMessage, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final fac = facilities[index];
              // TODO: 알람 발생 여부는 추후 백엔드 데이터에 맞춰 실제 필드로 교체
              final bool hasAlarm = index % 2 == 0; // 임시: 짝수 인덱스에만 알람 표시

              return Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onFacilityPressed(fac['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.outline),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            fac['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary, fontSize: 13),
                          ),
                        ),
                        if (hasAlarm)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: context.colors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.colors.surface, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
