class AppVersion {
  const AppVersion._();

  static const current = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  static String? fromManifest(Map<String, Object?> manifest) {
    final version = manifest['version'];
    final buildNumber = manifest['build_number'];
    if (version is! String || version.isEmpty) return null;
    return buildNumber == null || buildNumber.toString().isEmpty
        ? version
        : '$version+$buildNumber';
  }

  static bool isNewer(String available, {String current = current}) {
    final availableParts = _parse(available);
    final currentParts = _parse(current);
    if (availableParts == null || currentParts == null) return false;

    for (var index = 0; index < availableParts.length; index++) {
      if (availableParts[index] > currentParts[index]) return true;
      if (availableParts[index] < currentParts[index]) return false;
    }
    return false;
  }

  static List<int>? _parse(String version) {
    final match = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$',
    ).firstMatch(version.trim());
    if (match == null) return null;
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.tryParse(match.group(4) ?? '') ?? 0,
    ];
  }
}
