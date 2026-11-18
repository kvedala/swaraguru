import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import '../../app_version.dart';
import '../../theme/swara_theme.dart';

class WebVersionBadge extends StatefulWidget {
  const WebVersionBadge({super.key});

  @override
  State<WebVersionBadge> createState() => _WebVersionBadgeState();
}

class _WebVersionBadgeState extends State<WebVersionBadge> {
  static const _checkInterval = Duration(minutes: 15);

  Timer? _timer;
  String? _availableVersion;
  String? _checkError;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkForUpdate());
    _timer = Timer.periodic(
      _checkInterval,
      (_) => unawaited(_checkForUpdate()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (_checking) return;
    _checking = true;
    try {
      final versionUrl = Uri.parse(web.document.baseURI)
          .resolve('version.json')
          .replace(
            queryParameters: {
              'check': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
      final response = await web.window
          .fetch(versionUrl.toString().toJS)
          .toDart;
      if (!response.ok) {
        throw StateError('HTTP ${response.status}');
      }
      final body = (await response.text().toDart).toDart;
      final manifest = jsonDecode(body) as Map<String, Object?>;
      final available = AppVersion.fromManifest(manifest);
      if (!mounted) return;
      setState(() {
        _availableVersion = available != null && AppVersion.isNewer(available)
            ? available
            : null;
        _checkError = null;
      });
    } catch (error) {
      debugPrint('SwaraGuru update check failed: $error');
      if (!mounted) return;
      setState(() => _checkError = error.toString());
    } finally {
      _checking = false;
    }
  }

  void _reload() => web.window.location.reload();

  @override
  Widget build(BuildContext context) {
    final available = _availableVersion;
    final tooltip = available != null
        ? 'Version $available is available. Reload to update.'
        : _checkError != null
        ? 'Could not check for updates. Tap to retry.'
        : 'Current version ${AppVersion.current}';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: SwaraColors.midnightBg.withValues(alpha: 0.94),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SwaraColors.borderGold),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: available != null
              ? _reload
              : _checkError != null
              ? () => unawaited(_checkForUpdate())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (available != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      size: 17,
                      color: SwaraColors.brightGold,
                    ),
                  )
                else if (_checkError != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                Text(
                  'v${AppVersion.current}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
