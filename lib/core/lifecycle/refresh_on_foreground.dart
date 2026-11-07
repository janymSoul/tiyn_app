import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "This tab was just selected". A new instance per tap, so tapping the tab
/// that is already open fires too.
class TabSelected {
  TabSelected(this.tab);

  final Object tab;
}

class TabSelectedNotifier extends Notifier<TabSelected?> {
  @override
  TabSelected? build() => null;

  void selected(Object tab) => state = TabSelected(tab);
}

final tabSelectedProvider = NotifierProvider<TabSelectedNotifier, TabSelected?>(
  TabSelectedNotifier.new,
);

/// There is no push in Phase 1, so a list refetches itself when the app comes
/// back to the foreground and when its tab is selected. Every list screen
/// wraps its content in this instead of re-implementing the pattern.
///
/// [onRefresh] must be silent: the old data stays on screen and a failed
/// refetch shows nothing.
///
/// On resume only the screen that is actually visible refetches; the other
/// tabs of an `IndexedStack` are kept alive but are not ticking.
class RefreshOnForeground extends ConsumerStatefulWidget {
  const RefreshOnForeground({
    super.key,
    required this.tab,
    required this.onRefresh,
    required this.child,
  });

  /// The tab this screen belongs to (a detail screen uses its tab's value).
  final Object tab;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  ConsumerState<RefreshOnForeground> createState() =>
      _RefreshOnForegroundState();
}

class _RefreshOnForegroundState extends ConsumerState<RefreshOnForeground> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted && TickerMode.valuesOf(context).enabled) widget.onRefresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tabSelectedProvider, (_, selected) {
      if (selected != null && selected.tab == widget.tab) widget.onRefresh();
    });
    return widget.child;
  }
}
