part of 'settings_page.dart';

/// The timer tab: choose a length, start, and hear the time left every
/// minute.
class _TimerView extends StatefulWidget {
  const _TimerView({required this.controller});

  final AppController controller;

  @override
  State<_TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<_TimerView> {
  static const _presets = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];

  late int _minutes = widget.controller.settings.timerMinutes;

  AppController get controller => widget.controller;

  void _setMinutes(int minutes) =>
      setState(() => _minutes = minutes.clamp(1, maxTimerMinutes));

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    final theme = Theme.of(context);
    final countdown = controller.countdown;
    final running = countdown.running;
    final total = running ? countdown.total : Duration(minutes: _minutes);
    final left = running ? countdown.remaining : total;
    final minutesLeft = (left.inSeconds / 60).ceil();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        ColoredBox(
          color: theme.brightness == Brightness.dark ? Sky.bandNight : Sky.band,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox.square(
                dimension: 260,
                child: CustomPaint(
                  painter: _CountdownPainter(
                    total: total,
                    left: left,
                    color: theme.colorScheme.primary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.countdownFace(left),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          running && minutesLeft > 0
                              ? timeLeftTokens(minutesLeft).text
                              : t.timerReady,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: running
                    ? OutlinedButton.icon(
                        onPressed: controller.stopTimer,
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(t.stopTimer),
                      )
                    : FilledButton.icon(
                        onPressed: () => controller.startTimer(_minutes),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(t.startTimer),
                      ),
              ),
              if (!running)
                _Section(
                  title: t.timerTab,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.outlined(
                            tooltip: '−1',
                            onPressed: _minutes > 1
                                ? () => _setMinutes(_minutes - 1)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(
                              t.minutes(_minutes),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: '+1',
                            onPressed: _minutes < maxTimerMinutes
                                ? () => _setMinutes(_minutes + 1)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in _presets)
                            ChoiceChip(
                              label: Text(t.minutes(m)),
                              selected: m == _minutes,
                              showCheckmark: false,
                              onSelected: (_) => _setMinutes(m),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _Note(
                controller.voiceCountsDown
                    ? t.timerHint
                    : t.timerClassic(controller.voice.manifest.name),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A ring of dots, one per minute of the timer (one per five minutes for
/// timers over an hour), lit for the time left and dimmed as it passes,
/// in the same dot language as the clock's dial.
class _CountdownPainter extends CustomPainter {
  _CountdownPainter({
    required this.total,
    required this.left,
    required this.color,
  });

  final Duration total;
  final Duration left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 * 0.86;
    final c = size.center(Offset.zero);
    final unit = total.inMinutes > 60 ? 5 : 1;
    final count = math.max(1, (total.inMinutes / unit).ceil());
    final lit = (left.inSeconds / (unit * 60)).ceil();
    final pitch = 2 * math.pi * r / count;
    final dot = math.min(size.shortestSide * 0.022, pitch * 0.28);
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i / count * 2 * math.pi;
      canvas.drawCircle(
        c + Offset(math.cos(angle), math.sin(angle)) * r,
        i % (unit == 1 ? 5 : 3) == 0 ? dot * 1.35 : dot,
        Paint()..color = i < lit ? color : color.withValues(alpha: 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(_CountdownPainter old) =>
      old.left.inSeconds != left.inSeconds ||
      old.total != total ||
      old.color != color;
}
