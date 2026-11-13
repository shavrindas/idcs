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
              initiallyExpanded: parent.isExpanded,
              title: Text(
                parent.parentName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
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