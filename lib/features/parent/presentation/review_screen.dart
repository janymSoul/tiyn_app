import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/core/format/deadline_label.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/parent/application/review_providers.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_repository.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// What the parent typed into the redo / reject sheet.
class _Decision {
  const _Decision({this.note, this.deadline});

  final String? note;
  final DateTime? deadline;
}

/// One submitted task: info, the proof, and the three decisions.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _busy = false;

  /// Photo load failures answered by refetching the proofs (the presigned URL
  /// may have expired). One automatic refetch, then the user decides.
  int _photoRefetches = 0;

  String get _id => widget.taskId;

  void _reload() {
    ref.invalidate(taskDetailProvider(_id));
    ref.invalidate(proofsProvider(_id));
    setState(() => _photoRefetches = 0);
  }

  /// The lists that mention this task, so they are right when we go back.
  void _refreshLists(Task? task) {
    unawaited(ref.read(submittedTasksProvider.notifier).refresh());
    unawaited(ref.read(assignedTasksProvider.notifier).refresh());
    if (task != null) {
      final teen = taskListProvider(TaskQuery.forTeen(task.teenId));
      if (ref.exists(teen)) unawaited(ref.read(teen.notifier).refresh());
    }
  }

  Future<void> _decide(
    Task task,
    Future<Task> Function(TaskRepository repository) call,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call(ref.read(taskRepositoryProvider));
      _refreshLists(task);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (e.code == 'invalid_transition' ||
          e.code == 'concurrent_modification') {
        // Someone (or the clock) moved the task first: show how it is now.
        messenger.showSnackBar(SnackBar(content: Text(l10n.reviewChanged)));
        _refreshLists(task);
        if (mounted) _reload();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(apiErrorMessage(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redo(Task task, String teenName) async {
    final decision = await showModalBottomSheet<_Decision>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DecisionSheet(teenName: teenName, redo: true),
    );
    if (decision == null || !mounted) return;
    await _decide(
      task,
      (r) => r.requestRedo(
        task.id,
        note: decision.note,
        deadlineAt: decision.deadline,
      ),
    );
  }

  Future<void> _reject(Task task, String teenName) async {
    final decision = await showModalBottomSheet<_Decision>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DecisionSheet(teenName: teenName, redo: false),
    );
    if (decision == null || !mounted) return;
    await _decide(task, (r) => r.reject(task.id, note: decision.note));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = ref.watch(taskDetailProvider(_id));
    final names = ref.watch(familyNamesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          l10n.navToCheck,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: task.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErrorCard(
                message: apiErrorMessage(l10n, e),
                onRetry: () => ref.invalidate(taskDetailProvider(_id)),
              ),
            ],
          ),
          data: (t) => _content(context, t, names[t.teenId] ?? ''),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Task task, String teenName) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final canDecide = task.state == TaskState.submitted;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        if (teenName.isNotEmpty)
          Text(
            teenName,
            style: text.bodyMedium?.copyWith(color: Palette.muted),
          ),
        const SizedBox(height: Space.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  task.title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.s12),
            MoneyText(
              task.reward,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: Space.s8),
        Wrap(
          spacing: Space.s12,
          runSpacing: Space.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              deadlineLabel(
                l10n,
                MaterialLocalizations.of(context),
                task.deadlineAt,
                now: DateTime.now(),
              ),
              style: text.bodyMedium?.copyWith(color: Palette.muted),
            ),
            StateChip(task.state),
          ],
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: Space.s12),
          Text(task.description, style: text.bodyMedium?.copyWith(height: 1.5)),
        ],
        const SizedBox(height: Space.s20),
        _proof(context, teenName),
        const SizedBox(height: Space.s24),
        if (canDecide) ...[
          BusyButton(
            busy: _busy,
            onPressed: () => _decide(task, (r) => r.approve(task.id)),
            child: Text(l10n.reviewApprove),
          ),
          const SizedBox(height: Space.s12),
          OutlinedButton(
            onPressed: _busy ? null : () => _redo(task, teenName),
            child: Text(l10n.reviewRedo),
          ),
          const SizedBox(height: Space.s4),
          TextButton(
            onPressed: _busy ? null : () => _reject(task, teenName),
            style: TextButton.styleFrom(foregroundColor: Palette.warn),
            child: Text(l10n.reviewReject),
          ),
        ],
      ],
    );
  }

  Widget _proof(BuildContext context, String teenName) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final proofs = ref.watch(proofsProvider(_id));
    return proofs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Space.s32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorCard(
        message: apiErrorMessage(l10n, e),
        onRetry: () => ref.invalidate(proofsProvider(_id)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            l10n.reviewNoProof,
            style: text.bodyMedium?.copyWith(color: Palette.muted),
          );
        }
        final latest = list.reduce(
          (a, b) => a.attemptNo >= b.attemptNo ? a : b,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.reviewProofLabel} · ${l10n.reviewAttempt(latest.attemptNo)}',
              style: text.titleSmall?.copyWith(color: Palette.muted),
            ),
            const SizedBox(height: Space.s8),
            _proofBody(context, latest),
          ],
        );
      },
    );
  }

  Widget _proofBody(BuildContext context, Proof proof) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final url = proof.imageUrl;
    if (url == null) {
      return AppCard(
        child: SelectableText(
          proof.text ?? '',
          style: text.bodyLarge?.copyWith(height: 1.5),
        ),
      );
    }
    // Image.network keeps decoded images in memory only; the presigned URL is
    // never written to disk or logged.
    return Semantics(
      button: true,
      hint: l10n.reviewZoomHint,
      child: GestureDetector(
        onTap: () => _zoom(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (context, error, stack) {
              if (_photoRefetches == 0) {
                // The link probably expired: fetch fresh ones, once.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _photoRefetches != 0) return;
                  setState(() => _photoRefetches = 1);
                  ref.invalidate(proofsProvider(_id));
                });
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _PhotoFailed(
                onRetry: () {
                  setState(() => _photoRefetches = 0);
                  ref.invalidate(proofsProvider(_id));
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _zoom(String url) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: Image.network(url)),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    tooltip: AppLocalizations.of(context).actionClose,
                    onPressed: () => Navigator.of(context).pop(),
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

class _PhotoFailed extends StatelessWidget {
  const _PhotoFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reviewPhotoFailed,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Palette.warn),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.actionTryAgain)),
        ],
      ),
    );
  }
}

/// Note (and, for a redo, an optional new deadline) before the decision is
/// sent. Rejecting says plainly that it is final.
class _DecisionSheet extends StatefulWidget {
  const _DecisionSheet({required this.teenName, required this.redo});

  final String teenName;
  final bool redo;

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  final _note = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(
      () => _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.redo ? l10n.reviewRedoTitle : l10n.reviewRejectTitle,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Space.s8),
            Text(
              widget.redo
                  ? l10n.reviewRedoHint(widget.teenName)
                  : l10n.reviewRejectBody(widget.teenName),
              style: text.bodyMedium?.copyWith(
                color: widget.redo ? Palette.muted : Palette.warn,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Space.s16),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.reviewNote),
            ),
            if (widget.redo) ...[
              const SizedBox(height: Space.s8),
              OutlinedButton(
                onPressed: _pick,
                child: Text(
                  _deadline == null
                      ? l10n.reviewDeadlineKeep
                      : '${l10n.reviewDeadlineChange}: '
                            '${material.formatShortMonthDay(_deadline!)}, '
                            '${material.formatTimeOfDay(TimeOfDay.fromDateTime(_deadline!), alwaysUse24HourFormat: true)}',
                ),
              ),
            ],
            const SizedBox(height: Space.s16),
            FilledButton(
              style: widget.redo
                  ? null
                  : FilledButton.styleFrom(backgroundColor: Palette.warn),
              onPressed: () =>
                  Navigator.of(context)
                      .pop(_Decision(note: _note.text, deadline: _deadline)),
              child: Text(widget.redo ? l10n.actionSend : l10n.reviewReject),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
          ],
        ),
      ),
    );
  }
}
