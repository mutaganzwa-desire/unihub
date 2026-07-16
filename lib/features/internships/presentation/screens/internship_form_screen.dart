import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/internship.dart';
import '../providers/internship_providers.dart';

/// Create or edit an internship. Only reachable by verified startups —
/// enforced in the UI (ManageInternshipsScreen) and by Firestore rules.
class InternshipFormScreen extends ConsumerStatefulWidget {
  const InternshipFormScreen({super.key, this.internshipId});
  final String? internshipId;

  bool get isEditing => internshipId != null;

  @override
  ConsumerState<InternshipFormScreen> createState() =>
      _InternshipFormScreenState();
}

class _InternshipFormScreenState extends ConsumerState<InternshipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _responsibilities = TextEditingController();
  final _requirements = TextEditingController();
  final _skills = TextEditingController();
  final _location = TextEditingController();
  final _duration = TextEditingController();
  final _compensation = TextEditingController();
  final _positions = TextEditingController(text: '1');
  final _department = TextEditingController();
  final _tags = TextEditingController();
  final _instructions = TextEditingController();

  String _category = AppConstants.internshipCategories.first;
  String _workMode = AppConstants.workModes.last;
  String _employmentType = AppConstants.employmentTypes.first;
  DateTime? _deadline;
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in [
      _title, _description, _responsibilities, _requirements, _skills,
      _location, _duration, _compensation, _positions, _department, _tags,
      _instructions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(Internship i) {
    if (_prefilled) return;
    _prefilled = true;
    _title.text = i.title;
    _description.text = i.description;
    _responsibilities.text = i.responsibilities.join('\n');
    _requirements.text = i.requirements.join('\n');
    _skills.text = i.skills.join(', ');
    _location.text = i.location;
    _duration.text = i.durationWeeks == 0 ? '' : '${i.durationWeeks}';
    _compensation.text = i.compensation;
    _positions.text = '${i.positions}';
    _department.text = i.department;
    _tags.text = i.tags.join(', ');
    _instructions.text = i.applicationInstructions;
    _category = i.category;
    _workMode = i.workMode;
    _employmentType = i.employmentType;
    _deadline = i.deadline;
  }

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  List<String> _csv(TextEditingController c) => c.text
      .split(',')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  Future<void> _save(Internship? existing) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider)!;
    final startup = ref.read(myStartupProfileProvider).value;

    setState(() => _saving = true);
    final internship = Internship(
      id: existing?.id ?? '',
      startupId: user.uid,
      startupName: startup?.name ?? user.displayName,
      startupLogoUrl: startup?.logoUrl,
      title: _title.text.trim(),
      description: _description.text.trim(),
      responsibilities: _lines(_responsibilities),
      requirements: _lines(_requirements),
      skills: _csv(_skills),
      category: _category,
      department: _department.text.trim(),
      tags: _csv(_tags),
      workMode: _workMode,
      employmentType: _employmentType,
      location: _location.text.trim(),
      durationWeeks: int.tryParse(_duration.text) ?? 0,
      compensation: _compensation.text.trim(),
      deadline: _deadline,
      positions: int.tryParse(_positions.text) ?? 1,
      applicationInstructions: _instructions.text.trim(),
      status: existing?.status ?? InternshipStatus.open,
      postedAt: existing?.postedAt,
    );

    final repo = ref.read(internshipRepositoryProvider);
    final result = widget.isEditing
        ? await repo.update(internship)
        : await repo.create(internship);

    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        context.showSnack(
            widget.isEditing ? 'Internship updated.' : 'Internship published.');
        context.pop();
      },
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    Internship? existing;
    if (widget.isEditing) {
      final async = ref.watch(internshipProvider(widget.internshipId!));
      existing = async.value;
      if (existing != null) _prefill(existing);
      if (async.isLoading && !_prefilled) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    Widget dropdown(String label, List<String> options, String value,
            ValueChanged<String> onChanged) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(label, style: context.text.labelLarge),
            ),
            DropdownButtonFormField<String>(
              value: value,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => setState(() => onChanged(v!)),
            ),
            const SizedBox(height: 16),
          ],
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit internship' : 'New internship'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              label: 'Title',
              controller: _title,
              validator: (v) => Validators.required(v, 'Title'),
              hint: 'e.g. Flutter Developer',
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Description',
              controller: _description,
              validator: (v) => Validators.required(v, 'Description'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Responsibilities (one per line)',
              controller: _responsibilities,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Requirements (one per line)',
              controller: _requirements,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Skills (comma separated)',
              controller: _skills,
              validator: (v) => Validators.required(v, 'Skills'),
              hint: 'Flutter, Dart, Firebase',
            ),
            const SizedBox(height: 16),
            dropdown('Category', AppConstants.internshipCategories, _category,
                (v) => _category = v),
            dropdown('Work mode', AppConstants.workModes, _workMode,
                (v) => _workMode = v),
            dropdown('Employment type', AppConstants.employmentTypes,
                _employmentType, (v) => _employmentType = v),
            AppTextField(label: 'Location', controller: _location),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Duration (weeks)',
                    controller: _duration,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Positions',
                    controller: _positions,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Compensation',
              controller: _compensation,
              hint: 'e.g. 50,000 RWF/month or Unpaid',
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Department', controller: _department),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Tags (comma separated)',
              controller: _tags,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Application instructions',
              controller: _instructions,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Application deadline'),
              subtitle:
                  Text(_deadline == null ? 'No deadline' : _deadline!.shortDate),
              trailing: const Icon(Icons.event_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate:
                      _deadline ?? DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: widget.isEditing ? 'Save changes' : 'Publish internship',
              loading: _saving,
              onPressed: () => _save(existing),
            ),
          ],
        ),
      ),
    );
  }
}
