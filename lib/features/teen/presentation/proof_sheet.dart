import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/features/tasks/application/proof_upload.dart';
import 'package:tiyn_app/features/tasks/application/task_detail_provider.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// Opens the proof sheet. Completes with true once the proof was accepted.
Future<bool> showProofSheet(
  BuildContext context, {
  required String taskId,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ProofSheet(taskId: taskId),
  );
  return done ?? false;
}

const maxProofText = 2000;

/// Take a photo, pick one, or write a note. The idempotency key is made when
/// the sheet opens and a retry of the same photo or note reuses it.
class ProofSheet extends ConsumerStatefulWidget {
  const ProofSheet({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<ProofSheet> createState() => _ProofSheetState();
}

class _ProofSheetState extends ConsumerState<ProofSheet> {
  late final ProofSubmitter _submitter;
  final _note = TextEditingController();
  bool _writing = false;

  @override
  void initState() {
    super.initState();
    final repository = ref.read(taskRepositoryProvider);
    _submitter = ProofSubmitter(
      sendText: (text, key) =>
          repository.submitText(widget.taskId, text, key: key),
      sendPhoto: (jpeg, key) => repository.submitPhoto(
        widget.taskId,
        bytes: jpeg,
        filename: 'proof.jpg',
        contentType: 'image/jpeg',
        key: key,
      ),
      picker: ref.read(photoPickerProvider),
      encoder: ref.read(photoEncoderProvider),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _submitter.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _finish(Future<bool> attempt) async {
    final ok = await attempt;
    if (!mounted) return;
    if (ok) {
      ref.invalidate(taskDetailProvider(widget.taskId));
      await ref.read(dashboardControllerProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(true);
    } else if (_submitter.error is ApiException &&
        _isStale(_submitter.error! as ApiException)) {
      // The task moved on (deadline, or already sent): show how it is now.
      ref.invalidate(taskDetailProvider(widget.taskId));
      unawaited(ref.read(dashboardControllerProvider.notifier).refresh());
    }
  }

  bool _isStale(ApiException e) =>
      e.code == 'invalid_transition' || e.code == 'deadline_passed';

  String _message(AppLocalizations l10n, Object error) => switch (error) {
    ProofException(problem: ProofProblem.tooLarge) => l10n.proofTooLarge,
    ProofException(problem: ProofProblem.unreadable) => l10n.proofUnreadable,
    _ => apiErrorMessage(l10n, error),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final error = _submitter.error;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teenSubmitProof,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Space.s16),
            if (_writing) ...[
              TextField(
                controller: _note,
                enabled: !_submitter.busy,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: maxProofText,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.proofNoteLabel),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.s8),
              BusyButton(
                busy: _submitter.busy,
                onPressed: _note.text.trim().isEmpty
                    ? null
                    : () => _finish(_submitter.submitText(_note.text.trim())),
                child: Text(l10n.actionSend),
              ),
            ] else ...[
              BusyButton(
                busy: _submitter.busy,
                onPressed: () =>
                    _finish(_submitter.submitPhoto(PhotoOrigin.camera)),
                child: Text(l10n.proofTakePhoto),
              ),
              const SizedBox(height: Space.s12),
              BusyButton(
                outlined: true,
                busy: false,
                onPressed: _submitter.busy
                    ? null
                    : () =>
                          _finish(_submitter.submitPhoto(PhotoOrigin.gallery)),
                child: Text(l10n.proofChoosePhoto),
              ),
              const SizedBox(height: Space.s4),
              TextButton(
                onPressed: _submitter.busy
                    ? null
                    : () => setState(() => _writing = true),
                child: Text(l10n.proofWriteNote),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: Space.s12),
              Text(
                _message(l10n, error),
                style: text.bodyMedium?.copyWith(
                  color: Palette.warn,
                  height: 1.5,
                ),
              ),
              if (_submitter.canRetry && !_writing && !_submitter.busy)
                TextButton(
                  onPressed: () => _finish(_submitter.retry()),
                  child: Text(l10n.actionTryAgain),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
