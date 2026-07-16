import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../internships/domain/entities/internship.dart';
import '../../../internships/presentation/providers/internship_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/application.dart';
import '../providers/application_providers.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key, required this.internshipId});
  final String internshipId;

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivation = TextEditingController();
  String? _resumeUrl; // defaults to profile resume
  String? _coverLetterUrl;
  bool _submitting = false;

  @override
  void dispose() {
    _motivation.dispose();
    super.dispose();
  }

  Future<String?> _pickAndUpload(
      Future<String> Function(String uid, Uint8List bytes, String fileName)
          upload) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedResumeExtensions,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return null;
    final uid = ref.read(currentUserProvider)!.uid;
    try {
      return await upload(uid, file.bytes!, file.name);
    } catch (_) {
      if (mounted) context.showSnack('Upload failed. Try again.', error: true);
      return null;
    }
  }

  Future<void> _submit({required bool asDraft}) async {
    if (!asDraft && !_formKey.currentState!.validate()) return;
    final internship = ref.read(internshipProvider(widget.internshipId)).value;
    final user = ref.read(currentUserProvider);
    final profile = ref.read(myStudentProfileProvider).value;
    if (internship == null || user == null) return;

    final resume = _resumeUrl ?? profile?.resumeUrl;
    if (!asDraft && resume == null) {
      context.showSnack(
        'No resume attached yet — you can still submit and add one later.',
        error: false,
      );
    }

    setState(() => _submitting = true);
    final application = Application(
      id: '',
      internshipId: internship.id,
      internshipTitle: internship.title,
      startupId: internship.startupId,
      startupName: internship.startupName,
      startupLogoUrl: internship.startupLogoUrl,
      studentId: user.uid,
      studentName: profile?.fullName ?? user.displayName,
      studentPhotoUrl: profile?.photoUrl,
      motivation: _motivation.text.trim(),
      resumeUrl: resume,
      coverLetterUrl: _coverLetterUrl,
    );

    final res = await ref
        .read(applicationRepositoryProvider)
        .submit(application, asDraft: asDraft);
    if (!mounted) return;
    setState(() => _submitting = false);
    res.when(
      success: (_) {
        if (!asDraft) {
          ref
              .read(analyticsServiceProvider)
              .logApplicationSubmitted(internship.id);
        }
        ref.invalidate(myApplicationsProvider);
        ref.invalidate(myApplicationIdsProvider);
        ref.invalidate(internshipFeedProvider(InternshipFilter()));
        ref.invalidate(internshipProvider(widget.internshipId));
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(
              asDraft ? Icons.save_outlined : Icons.check_circle_rounded,
              color: Theme.of(ctx).colorScheme.primary,
              size: 44,
            ),
            title: Text(asDraft ? 'Draft saved' : 'Application sent!'),
            content: Text(
              asDraft
                  ? 'You can finish and submit it later from My Applications.'
                  : 'Track its status in My Applications — you will be notified about every update.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final internship = ref.watch(internshipProvider(widget.internshipId)).value;
    final profileResume = ref.watch(myStudentProfileProvider).value?.resumeUrl;
    final storage = ref.read(storageServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (internship != null) ...[
              Text(internship.title, style: context.text.titleLarge),
              Text(internship.startupName,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.primary)),
              const SizedBox(height: 20),
            ],
            Text('Motivation', style: context.text.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              controller: _motivation,
              maxLines: 6,
              validator: (v) => Validators.required(v, 'Motivation'),
              decoration: const InputDecoration(
                hintText:
                    'Why are you a great fit for this role? Mention relevant projects and skills.',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf_rounded,
                    color: context.colors.primary),
                title: Text(
                  _resumeUrl != null
                      ? 'Resume attached'
                      : profileResume != null
                          ? 'Using resume from your profile'
                          : 'Attach resume (PDF)',
                ),
                subtitle: const Text('Tap to upload a different file'),
                onTap: () async {
                  final url = await _pickAndUpload(storage.uploadResume);
                  if (url != null) setState(() => _resumeUrl = url);
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.description_outlined,
                    color: context.colors.primary),
                title: Text(_coverLetterUrl != null
                    ? 'Cover letter attached'
                    : 'Attach cover letter (optional)'),
                onTap: () async {
                  final url = await _pickAndUpload(storage.uploadCoverLetter);
                  if (url != null) setState(() => _coverLetterUrl = url);
                },
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit application',
              loading: _submitting,
              onPressed: () => _submit(asDraft: false),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _submitting ? null : () => _submit(asDraft: true),
              child: const Text('Save as draft'),
            ),
          ],
        ),
      ),
    );
  }
}
