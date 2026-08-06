import 'package:flutter/material.dart';

/// Box #2: 통합 시설 박스 (순수 목록 표시 및 이벤트 전달)
class UserAlarmBox extends StatelessWidget {
  final List<dynamic> alarms;
  final Function(int) onFacilityPressed;
  final bool isSearching;

  const UserAlarmBox({
    super.key,
    required this.alarms,
    required this.onFacilityPressed,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '통합 알람 박스',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 알람 목록 또는 안내 문구
          if (alarms.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  isSearching ? '검색 결과가 없습니다.' : '조회할 수 있는 시설이 없습니다.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                final bool hasAlarm = index % 2 == 0;

                // 백엔드에서 넘겨주는 날짜 키값 및 facility_id 확인
                final rawTime = alarm['timestamp']?.toString() ?? '';
                final int facilityId = alarm['facility_id'] is int
                    ? alarm['facility_id']
                    : int.tryParse(alarm['facility_id']?.toString() ?? '0') ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      // 터치 시 전달받은 콜백 함수 실행
                      onFacilityPressed(facilityId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alarm['alarm_name'] ?? '알람 이름 없음',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rawTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasAlarm)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
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
      ),
    );
  }
}