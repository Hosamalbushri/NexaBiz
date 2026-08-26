import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BuildEdition {
  free,
  premium,
}

class BuildEditionInspector {
  const BuildEditionInspector._();

  static const String _editionDefine = String.fromEnvironment(
    'APP_EDITION',
    defaultValue: 'premium',
  );

  static BuildEdition get currentEdition {
    switch (_editionDefine.toLowerCase()) {
      case 'free':
        return BuildEdition.free;
      case 'premium':
      default:
        return BuildEdition.premium;
    }
  }

  static bool get isFreeEdition => currentEdition == BuildEdition.free;
  static bool get isPremiumEdition => currentEdition == BuildEdition.premium;
}

final buildEditionProvider = Provider<BuildEdition>((ref) {
  return BuildEditionInspector.currentEdition;
});
