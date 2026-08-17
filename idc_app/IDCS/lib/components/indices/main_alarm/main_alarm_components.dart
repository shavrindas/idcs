import 'package:flutter/material.dart';



/// Box #2: 통합 시설 박스 (빈 박스로 임시 편성)
class IntegratedFacilityBox extends StatelessWidget {
  final List<dynamic> facilities;
  final Function(int) onFacilityPressed;

  const IntegratedFacilityBox({
    super.key, required this.facilities, required this.onFacilityPressed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('통합 시설 박스', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (facilities.isEmpty)
            const Center(child: Text('조회할 수 있는 시설이 없습니다.', style: TextStyle(color: Colors.grey))),

          // Grid 형태로 카드 배치
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2열 배치
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5, // 카드 비율
            ),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final fac = facilities[index];
              // TODO: 알람 발생 여부는 추후 백엔드 데이터에 맞춰 실제 필드로 교체
              final bool hasAlarm = false; // 임시: 짝수 인덱스에만 알람 표시

              return InkWell(
                onTap: () => onFacilityPressed(fac['id']),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Center(child: Text(fac['name'], textAlign: TextAlign.center)),
                      if (hasAlarm) // 알람 레드 닷
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}