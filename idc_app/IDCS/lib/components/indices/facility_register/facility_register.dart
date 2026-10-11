import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #2: 시설 접근 코드 입력 및 등록 박스
class FacilityInputBox extends StatelessWidget {
  final TextEditingController codeController;
  final VoidCallback onSubmit;
  final String collapseMessage;

  const FacilityInputBox({
    super.key, required this.codeController, required this.onSubmit, required this.collapseMessage
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.facilityRegister, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: context.l10n.facilityAccessCode,
              prefixIcon: Icon(Icons.qr_code_outlined),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onSubmit, child: Text(context.l10n.facilityRegister)),
          if (collapseMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: context.colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      collapseMessage,
                      style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

/// Box #3: 등록된 시설 리스트 및 해제 박스
class FacilityListEditBox extends StatelessWidget {
  final List<dynamic> facilities;
  final Function(int) onUnlink;

  const FacilityListEditBox({super.key, required this.facilities, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.facilityRegistered, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
          const SizedBox(height: 12),
          if (facilities.isEmpty)
            Text(context.l10n.facilitiesEmpty, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
          ...facilities.map((fac) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.outline),
                      ),
                      child: Text(fac['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => onUnlink(fac['id']),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: context.colors.error,
                      side: BorderSide(color: context.colors.error.withValues(alpha: 0.4)),
                    ),
                    child: Text(context.l10n.facilityUnlink),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
