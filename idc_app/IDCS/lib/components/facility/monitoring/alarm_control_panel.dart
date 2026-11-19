import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/responsive.dart';

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

        // 꺼진 항목은 목록을 접어도 바로 켤 수 있어야 한다 — 이름만 보여주면
        // 결국 펼쳐서 같은 스위치를 다시 찾아야 했다. 꺼진 항목만 토글과
        // 함께 이 카드(헤더) 안에 미리 꺼내 둔다.
        final offChildren = parent.children.where((c) => !c.isActive).toList();

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
                  fontSize: context.scale(15),
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              subtitle: offChildren.isEmpty
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final child in offChildren)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: context.colors.textSecondary.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    child.displayName.isNotEmpty ? child.displayName : child.roleName,
                                    style: TextStyle(fontSize: context.scale(12), color: context.colors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: child.isActive,
                                    onChanged: (bool value) => child.onToggle(value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                        fontSize: context.scale(14),
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