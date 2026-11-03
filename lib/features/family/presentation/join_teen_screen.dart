import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/info_banner.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class JoinTeenScreen extends ConsumerStatefulWidget {
  const JoinTeenScreen({super.key});

  @override
  ConsumerState<JoinTeenScreen> createState() => _JoinTeenScreenState();
}

class _JoinTeenScreenState extends ConsumerState<JoinTeenScreen> {
  static const _codeLength = 6;
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.length < _codeLength) {
      setState(() => _error = AppLocalizations.of(context).joinCodeTooShort);
      return;
    }
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
                maxLength: _codeLength,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  counterText: '',
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
                onChanged: (_) =>
                    _error == null ? null : setState(() => _error = null),
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
                onPressed: _join,
                child: Text(l10n.joinConnect),
              ),
              const SizedBox(height: Space.s24),
              InfoBanner(l10n.joinMultiParentInfo),
            ],
          ),
        ),
      ),
    );
  }
}
