import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/host_os.dart';
import '../app/version.dart';
import '../core/update/release.dart';

/// Offers [release]: installs it where the app can (Windows, installed with
/// the setup), and otherwise opens its download page.
Future<void> showUpdateDialog(
  BuildContext context,
  AppController controller,
  Release release,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _UpdateDialog(controller: controller, release: release),
);

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.controller, required this.release});

  final AppController controller;
  final Release release;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  /// The download's progress, 0–1, while installing.
  double? _progress;
  var _failed = false;

  AppController get controller => widget.controller;
  bool get _installs => controller.canInstallUpdates && !_failed;

  Future<void> _primary() async {
    if (!_installs) {
      await controller.openLink('${widget.release.page}');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _progress = 0);
    try {
      await controller.installUpdate(
        widget.release,
        progress: (p) => setState(() => _progress = p),
      );
    } on Object {
      if (mounted) {
        setState(() {
          _progress = null;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = _progress != null;
    final notes = widget.release.plainNotes;
    return AlertDialog(
      title: Text(t.updateTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.updateBody('${widget.release.version}', appVersion)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 220,
                  minWidth: double.infinity,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (hostOs == HostOs.macos) ...[
              const SizedBox(height: 12),
              Text(t.brewHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              // Homebrew refreshes taps about once a day on its own, so a
              // plain upgrade soon after a release still sees the old one.
              const SelectableText(
                'brew update && brew upgrade --cask bangla-voice-clock',
                style: TextStyle(fontFamily: 'Menlo', fontSize: 13),
              ),
            ],
            if (_progress case final progress?) ...[
              const SizedBox(height: 16),
              Text(t.downloading),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress),
            ],
            if (_failed) ...[
              const SizedBox(height: 12),
              Text(t.updateFailed, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy
              ? null
              : () {
                  controller.skipUpdate(widget.release);
                  Navigator.of(context).pop();
                },
          child: Text(t.skipVersion),
        ),
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: Text(t.later),
        ),
        FilledButton(
          onPressed: busy ? null : _primary,
          child: Text(_installs ? t.updateNow : t.openDownload),
        ),
      ],
    );
  }
}
