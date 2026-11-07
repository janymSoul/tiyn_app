import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/push/presentation/notify_prompt_sheet.dart';
import 'package:tiyn_app/features/tasks/application/create_task_controller.dart';
import 'package:tiyn_app/features/tasks/application/task_form.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// What the form was opened for. From a milestone (P5) [milestoneId] fixes the
/// parent milestone and [milestoneDeadline] bounds the deadline.
class CreateTaskArgs {
  const CreateTaskArgs({
    required this.teenId,
    this.kind = TaskKind.task,
    this.milestoneId,
    this.milestoneDeadline,
  });

  final String teenId;
  final TaskKind kind;
  final String? milestoneId;
  final DateTime? milestoneDeadline;
}

/// Full-screen form for a task or a milestone.
class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key, required this.args, this.clock});

  final CreateTaskArgs args;

  /// For tests: "now" for the default deadline and the future check.
  final DateTime Function()? clock;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _title = TextEditingController();
  final _reward = TextEditingController();
  final _penalty = TextEditingController();
  final _description = TextEditingController();
  late final CreateTaskController _create;
  late DateTime _deadline;

  bool _showErrors = false;
  bool _penaltyOpen = false;
  final _serverErrors = <TaskField, String>{};

  bool get _isMilestone => widget.args.kind == TaskKind.milestone;
  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _create = CreateTaskController(
      send: (task, key) =>
          ref.read(taskRepositoryProvider).create(task, key: key),
    )..addListener(() => setState(() {}));
    _deadline = defaultDeadline(_now());
  }

  @override
  void dispose() {
    _create.dispose();
    _title.dispose();
    _reward.dispose();
    _penalty.dispose();
    _description.dispose();
    super.dispose();
  }

  TaskFormInput get _input => TaskFormInput(
    teenId: widget.args.teenId,
    kind: widget.args.kind,
    title: _title.text,
    description: _description.text,
    reward: _reward.text,
    penalty: _penalty.text,
    deadlineAt: _deadline.toUtc(),
    milestoneId: widget.args.milestoneId,
    milestoneDeadline: widget.args.milestoneDeadline,
  );

  void _edited(TaskField field) {
    _create.noteEdited();
    setState(() {
      _serverErrors.remove(field);
      _serverErrors.remove(TaskField.form);
    });
  }

  String _errorText(AppLocalizations l10n, TaskFormError e) {
    final max = formatMoney(
      maxTaskAmount,
      locale: Localizations.localeOf(context).languageCode,
    );
    return switch (e) {
      TaskFormError.titleRequired => l10n.errTitleRequired,
      TaskFormError.titleTooLong => l10n.errTitleTooLong,
      TaskFormError.amountInvalid => l10n.errAmountInvalid,
      TaskFormError.rewardRange => l10n.errRewardRange(max),
      TaskFormError.penaltyRange => l10n.errPenaltyRange(max),
      TaskFormError.deadlinePast => l10n.errDeadlinePast,
      TaskFormError.deadlineAfterMilestone => l10n.errDeadlineAfterMilestone,
    };
  }

  Future<void> _submit() async {
    // Taken before the await: the form is gone by the time they are needed.
    final navigator = Navigator.of(context, rootNavigator: true);
    final container = ProviderScope.containerOf(context);
    final pending = _create.pending;
    final NewTask task;
    if (_create.phase == CreatePhase.ambiguous && pending != null) {
      task = pending; // resend exactly what the server may have seen
    } else {
      setState(() => _showErrors = true);
      final validation = validateTask(_input, now: _now());
      if (!validation.isValid) return;
      task = validation.task!;
    }
    final ok = await _create.submit(task);
    if (!mounted) return;
    if (ok) {
      _refreshLists();
      final teenName = ref.read(familyNamesProvider)[widget.args.teenId];
      context.pop(true);
      unawaited(
        askForNotificationsAfterCreate(
          navigatorContext: navigator.context,
          container: container,
          teenName: teenName,
        ),
      );
      return;
    }
    final error = _create.error;
    if (_create.phase == CreatePhase.rejected && error != null) {
      setState(() {
        _serverErrors[fieldForServerCode(error.code)] = apiErrorMessage(
          AppLocalizations.of(context),
          error,
        );
      });
    }
  }

  void _refreshLists() {
    unawaited(ref.read(assignedTasksProvider.notifier).refresh());
    final teen = taskListProvider(TaskQuery.forTeen(widget.args.teenId));
    if (ref.exists(teen)) unawaited(ref.read(teen.notifier).refresh());
  }

  Future<void> _confirmEdit() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createEditWarnTitle),
        content: Text(l10n.createEditWarnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.createEditAnyway),
          ),
        ],
      ),
    );
    if (ok ?? false) _create.unlockToEdit();
  }

  Future<void> _pickDate() async {
    final now = _now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now) ? now : _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    if (picked == null) return;
    _edited(TaskField.deadline);
    setState(() {
      _deadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _deadline.hour,
        _deadline.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (picked == null) return;
    _edited(TaskField.deadline);
    setState(() {
      _deadline = DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final locked = _create.isLocked;
    final ambiguous = _create.phase == CreatePhase.ambiguous;
    final teenName = ref.watch(
      familyControllerProvider.select(
        (s) =>
            s.value
                ?.where((m) => m.id == widget.args.teenId)
                .map((m) => m.displayName)
                .firstOrNull ??
            '',
      ),
    );

    final errors = _showErrors
        ? validateTask(_input, now: _now()).errors
        : const <TaskField, TaskFormError>{};
    String? errorFor(TaskField f) =>
        _serverErrors[f] ??
        (errors[f] == null ? null : _errorText(l10n, errors[f]!));

    final formError = _serverErrors[TaskField.form];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.actionClose,
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isMilestone ? l10n.createMilestoneTitle : l10n.createTaskTitle,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            if (teenName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s16),
                child: Text(
                  l10n.createFor(teenName),
                  style: text.bodyMedium?.copyWith(color: Palette.muted),
                ),
              ),
            if (ambiguous) ...[
              _Banner(l10n.createUnsure),
              const SizedBox(height: Space.s16),
            ],
            TextField(
              controller: _title,
              enabled: !locked,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.fieldTitle,
                errorText: errorFor(TaskField.title),
                errorMaxLines: 3,
              ),
              onChanged: (_) => _edited(TaskField.title),
            ),
            const SizedBox(height: Space.s16),
            TextField(
              controller: _reward,
              enabled: !locked,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.fieldReward,
                errorText: errorFor(TaskField.reward),
                errorMaxLines: 3,
              ),
              onChanged: (_) => _edited(TaskField.reward),
            ),
            const SizedBox(height: Space.s16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PickerField(
                    label: l10n.fieldDeadlineDate,
                    value: material.formatMediumDate(_deadline),
                    onTap: locked ? null : _pickDate,
                  ),
                ),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: _PickerField(
                    label: l10n.fieldDeadlineTime,
                    value: material.formatTimeOfDay(
                      TimeOfDay.fromDateTime(_deadline),
                      alwaysUse24HourFormat: true,
                    ),
                    onTap: locked ? null : _pickTime,
                  ),
                ),
              ],
            ),
            if (errorFor(TaskField.deadline) case final message?)
              _FieldError(message),
            const SizedBox(height: Space.s16),
            TextField(
              controller: _description,
              enabled: !locked,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.fieldDescription),
              onChanged: (_) => _edited(TaskField.form),
            ),
            if (!_isMilestone) ...[
              const SizedBox(height: Space.s8),
              _PenaltyToggle(
                label: l10n.penaltyToggle,
                open: _penaltyOpen,
                onTap: locked
                    ? null
                    : () => setState(() => _penaltyOpen = !_penaltyOpen),
              ),
              if (_penaltyOpen) ...[
                const SizedBox(height: Space.s8),
                TextField(
                  controller: _penalty,
                  enabled: !locked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.fieldPenalty,
                    errorText: errorFor(TaskField.penalty),
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) => _edited(TaskField.penalty),
                ),
              ],
            ],
            if (formError != null) ...[
              const SizedBox(height: Space.s16),
              Text(
                formError,
                style: text.bodyMedium?.copyWith(
                  color: Palette.warn,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: Space.s24),
            BusyButton(
              busy: _create.phase == CreatePhase.sending,
              onPressed: _submit,
              child: Text(
                ambiguous
                    ? l10n.actionTryAgain
                    : _isMilestone
                    ? l10n.createAddMilestone
                    : l10n.createAddTask,
              ),
            ),
            if (ambiguous)
              TextButton(
                onPressed: _confirmEdit,
                child: Text(l10n.createEditDetails),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.input),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, enabled: onTap != null),
        child: Text(value),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Palette.warn),
      ),
    );
  }
}

class _PenaltyToggle extends StatelessWidget {
  const _PenaltyToggle({
    required this.label,
    required this.open,
    required this.onTap,
  });

  final String label;
  final bool open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Palette.muted),
                ),
              ),
              Icon(open ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.infoWash,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Palette.infoText, height: 1.5),
      ),
    );
  }
}
