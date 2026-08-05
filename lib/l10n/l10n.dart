import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Concise, null-safe access to the generated application localizations.
extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
