import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Data model representing remote app version policies.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.minimumSupportedVersion,
    this.forceUpdate = false,
    this.storeUrl,
    this.releaseNotes,
  });

  final String latestVersion;
  final String minimumSupportedVersion;
  final bool forceUpdate;
  final String? storeUrl;
  final String? releaseNotes;

  /// Compares two semver-like version strings ("1.4.0" vs "1.5.0").
  /// Returns negative if [v1] < [v2], 0 if equal, positive if [v1] > [v2].
  static int compareVersions(String v1, String v2) {
    List<int> parseSegments(String v) {
      final cleaned = v.split('+').first.split('-').first;
      return cleaned
          .split('.')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
    }

    final s1 = parseSegments(v1);
    final s2 = parseSegments(v2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    for (var i = 0; i < maxLength; i++) {
      final seg1 = i < s1.length ? s1[i] : 0;
      final seg2 = i < s2.length ? s2[i] : 0;
      if (seg1 != seg2) {
        return seg1.compareTo(seg2);
      }
    }
    return 0;
  }

  bool isMandatoryUpdate(String currentVersion) {
    if (forceUpdate) return true;
    return compareVersions(currentVersion, minimumSupportedVersion) < 0;
  }

  bool isOptionalUpdate(String currentVersion) {
    if (isMandatoryUpdate(currentVersion)) return false;
    return compareVersions(currentVersion, latestVersion) < 0;
  }
}

/// Gate widget that intercepts app flow if a mandatory or optional app update is required.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
    this.updateFetcher,
    this.currentVersionOverride,
    this.onOpenStore,
  });

  final Widget child;

  /// Optional custom update info fetcher. If null or fails, falls back gracefully.
  final Future<AppUpdateInfo?> Function()? updateFetcher;

  /// Optional current version string override for testing.
  final String? currentVersionOverride;

  /// Optional custom callback to launch the app store URL.
  final void Function(String? url)? onOpenStore;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  var _loading = true;
  String _currentVersion = '1.0.0';
  AppUpdateInfo? _updateInfo;
  var _dismissedOptional = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkUpdate());
  }

  Future<void> _checkUpdate() async {
    try {
      if (widget.currentVersionOverride != null) {
        _currentVersion = widget.currentVersionOverride!;
      } else {
        final info = await PackageInfo.fromPlatform();
        _currentVersion = info.version;
      }

      if (widget.updateFetcher != null) {
        _updateInfo = await widget.updateFetcher!();
      }
    } catch (_) {
      // Offline or error — proceed gracefully without blocking offline app startup
      _updateInfo = null;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _triggerOpenStore(String? url) {
    if (widget.onOpenStore != null) {
      widget.onOpenStore!(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.child;
    }

    final info = _updateInfo;
    if (info == null) {
      return widget.child;
    }

    final isMandatory = info.isMandatoryUpdate(_currentVersion);
    final isOptional = info.isOptionalUpdate(_currentVersion) && !_dismissedOptional;

    if (isMandatory) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.system_security_update_warning_outlined,
                  size: 72,
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),
                Text(
                  'Update Required',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A required update (v${info.latestVersion}) is available. Please update to continue using NexaBiz.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      info.releaseNotes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _triggerOpenStore(info.storeUrl),
                  icon: const Icon(Icons.download),
                  label: const Text('Update Now'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isOptional) {
      return Stack(
        children: [
          widget.child,
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.inverseSurface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Update Available (v${info.latestVersion})',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onInverseSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'An optional app update is available.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _dismissedOptional = true),
                      child: Text(
                        'Later',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _triggerOpenStore(info.storeUrl),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
