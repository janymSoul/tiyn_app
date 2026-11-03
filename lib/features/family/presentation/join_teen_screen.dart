import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/info_banner.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/presentation/join_code_formatter.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class JoinTeenScreen extends ConsumerStatefulWidget {
  const JoinTeenScreen({super.key});

  @override
  ConsumerState<JoinTeenScreen> createState() => _JoinTeenScreenState();
}

class _JoinTeenScreenState extends ConsumerState<JoinTeenScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _autoSubmitted;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text;
    if (code.length != joinCodeLength || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(familyControllerProvider.notifier).join(code);
    } on ApiException catch (e) {
      if (mounted) _error = apiErrorMessage(AppLocalizations.of(context), e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onChanged(String value) {
    setState(() => _error = null);
    // Submit once per distinct full code; after an error the user edits or
    // taps the button.
    if (value.length == joinCodeLength && value != _autoSubmitted) {
      _autoSubmitted = value;
      _join();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.joinTitle,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.s8),
              Text(
                l10n.joinSubtitle,
                style: text.bodyMedium?.copyWith(
                  color: Palette.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: Space.s32),
              Text(
                l10n.joinCodeLabel,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: Space.s8),
              TextField(
                controller: _code,
                enabled: !_busy,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [],
                inputFormatters: [JoinCodeFormatter()],
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Palette.navy, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Palette.navy, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Palette.navy, width: 2),
                  ),
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _join(),
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.s8),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(
                    color: Palette.warn,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: Space.s24),
              BusyButton(
                busy: _busy,
                onPressed: _code.text.length == joinCodeLength ? _join : null,
                child: Text(l10n.joinConnect),
              ),
              const SizedBox(height: Space.s24),
              InfoBanner(l10n.joinMultiParentInfo),
              const SizedBox(height: Space.s24),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.actionSignOut),
              ),
              Text(
                l10n.joinWrongAccountHint,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: Palette.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
