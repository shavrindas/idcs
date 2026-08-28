import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// 페이지 이동용 리스트 행 (탭 가능한 카드)
class NavigationBox extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final IconData icon;

  const NavigationBox({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon = Icons.chevron_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
