import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

// 1. 데이터 모델 정의 (부모와 자식 구조)
class ParentNode {
  String parentName;
  bool isExpanded;
  List<ChildNode> children;

  ParentNode({
    required this.parentName,
    this.isExpanded = true,
    required this.children,
  });
}

class ChildNode {
  final String roleId;
  final String roleName;
  final String displayName;
  final String? shortName;
  final String? target;
  bool isActive;
  final VoidCallback onTap;
  final ValueSetter<bool> onToggle;

  ChildNode({
    required this.roleId,
    required this.roleName,
    required this.displayName,
    this.shortName,
    this.target,
    required this.isActive,
    required this.onTap,
    required this.onToggle,
  });
}

class FacilityTreeViewTab extends StatelessWidget {
  final List<ParentNode> parentNodes;
  final bool isLoading;

  const FacilityTreeViewTab({
    super.key,
    required this.parentNodes,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (parentNodes.isEmpty) {
      return Center(
        child: Text(
          '표시할 포인트 롤 데이터가 없습니다.',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parentNodes.length,
      itemBuilder: (context, parentIndex) {
        final parent = parentNodes[parentIndex];

        // 꺼진 항목은 목록을 접어도 무엇이 꺼져 있는지 알 수 있어야 한다 —
        // 그러지 않으면 매번 펼쳐 봐야만 확인할 수 있었다.
        final offNames = parent.children
            .where((c) => !c.isActive)
            .map((c) => c.displayName.isNotEmpty ? c.displayName : c.roleName)
            .join(', ');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: context.colors.cardShadow,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              // ListView.builder가 화면 밖으로 멀리 스크롤된 항목을 버렸다가
              // 다시 지을 때, 키가 없으면 ExpansionTile이 펼침 상태를 잃고
              // initiallyExpanded(항상 true)로 되돌아갔다. 키로 PageStorage가
              // 상태를 기억하게 하고, onExpansionChanged로 parent.isExpanded도
              // 같이 맞춰 둔다.
              key: PageStorageKey('alarm_parent_${parentIndex}_${parent.parentName}'),
              initiallyExpanded: parent.isExpanded,
              onExpansionChanged: (expanded) => parent.isExpanded = expanded,
              title: Text(
                parent.parentName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              subtitle: offNames.isEmpty
                  ? null
                  : Text(
                      '꺼짐: $offNames',
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                    ),
              children: parent.children.map((child) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.colors.textSecondary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    onTap: child.onTap,
                    // 자식 제목 부분: display_name과 role_name을 분리해서 표시
                    title: Text(
                      child.displayName, // 메인으로 보여줄 이름 (예: 한글 명칭 등)
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    trailing: Switch(
                      value: child.isActive,
                      onChanged: (bool value) {
                        child.onToggle(value);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}