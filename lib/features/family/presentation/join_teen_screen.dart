import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';

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
      setState(
        () => _error = 'That code is too short. It has 6 letters or numbers.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(familyControllerProvider.notifier).join(code);
    } on ApiException catch (e) {
      _error = switch (e.code) {
        'invalid_join_code' =>
          'We could not find that code. Check it and try again.',
        'network_error' => 'No connection. Check your network.',
        _ => 'Could not connect (${e.code}).',
      };
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Enter your parent's code",
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask your mom or dad for the 6-letter code from their Tiyn app.',
                style: text.bodyMedium?.copyWith(
                  color: Palette.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Code',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(
                    color: Palette.warn,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _join,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Connect'),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Palette.infoWash,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'You can connect to more than one parent. Each of them can give you tasks.',
                  style: text.bodyMedium?.copyWith(
                    color: Palette.infoText,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
