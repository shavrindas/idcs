// 경로: lib/l10n/l10n_context.dart
// 명세: 번역 문구를 context.l10n 으로 짧게 꺼내 쓰기 위한 확장
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Mirrors the `context.colors` idiom already used for theme tokens, so a
/// translated string reads the same way a themed colour does.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
