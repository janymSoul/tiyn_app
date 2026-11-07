import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/router/router.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/push/application/push_banner_controller.dart';
import 'package:tiyn_app/features/push/application/push_location.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// Sits above the router (in `MaterialApp.builder`) so the banner covers
/// whatever screen is open. Not a `SnackBar`: there are several nested
/// `Scaffold`s and a snackbar would land on an arbitrary one.
class PushBannerHost extends ConsumerWidget {
  const PushBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(pushBannerProvider);
    return Stack(
      children: [
        child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(Space.s12),
                child: _Banner(key: ValueKey(banner.id), data: banner),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends ConsumerStatefulWidget {
  const _Banner({super.key, required this.data});

  final PushBannerData data;

  @override
  ConsumerState<_Banner> createState() => _BannerState();
}

class _BannerState extends ConsumerState<_Banner> {
  static const _visibleFor = Duration(seconds: 5);
  static const _visibleForScreenReader = Duration(seconds: 12);

  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once: this also runs when the keyboard or rotation changes MediaQuery,
    // and the banner must not get a fresh 5 seconds each time.
    if (_timer != null) return;
    final slow = MediaQuery.of(context).accessibleNavigation;
    _timer = Timer(slow ? _visibleForScreenReader : _visibleFor, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() =>
      ref.read(pushBannerProvider.notifier).dismiss(widget.data.id);

  void _open() {
    final role = ref.read(authControllerProvider).value?.role;
    _dismiss();
    if (role == null) return;
    ref.read(routerProvider).go(pushLocation(widget.data.payload, role));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final data = widget.data;
    final spoken = [
      data.title,
      data.body,
    ].where((s) => s.isNotEmpty).join('. ');

    return Dismissible(
      key: ValueKey('dismiss-${data.id}'),
      direction: DismissDirection.up,
      onDismissed: (_) => _dismiss(),
      child: Material(
        color: Palette.navy,
        elevation: 6,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s16,
            Space.s12,
            Space.s4,
            Space.s8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // One announcement for the text; the Open button stays a
                    // separate, reachable control.
                    Semantics(
                      liveRegion: true,
                      container: true,
                      excludeSemantics: true,
                      label: spoken,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.title.isNotEmpty)
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (data.body.isNotEmpty)
                            Text(
                              data.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                color: Palette.onNavyMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: _open,
                        style: TextButton.styleFrom(
                          foregroundColor: Palette.gold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(l10n.pushBannerOpen),
                      ),
                    ),
                  ],
                ),
              ),
              // No tooltip: this sits above the Navigator, so there is no
              // Overlay for one to use.
              Semantics(
                label: l10n.pushBannerDismiss,
                button: true,
                excludeSemantics: true,
                onTap: _dismiss,
                child: IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close, color: Palette.onNavyMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
