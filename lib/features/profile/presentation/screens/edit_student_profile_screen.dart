import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/student_profile.dart';
import '../providers/profile_providers.dart';

class EditStudentProfileScreen extends ConsumerStatefulWidget {
  const EditStudentProfileScreen({super.key});

  @override
  ConsumerState<EditStudentProfileScreen> createState() =>
      _EditStudentProfileScreenState();
}

class _EditStudentProfileScreenState
    extends ConsumerState<EditStudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _program = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  final _interests = TextEditingController();
  final _portfolio = TextEditingController();
  final _github = TextEditingController();
  final _linkedin = TextEditingController();
  final _location = TextEditingController();
  final _availability = TextEditingController();
  final _projects = TextEditingController();

  int _year = 1;
  Set<String> _categories = {};
  String? _photoUrl;
  String? _resumeUrl;
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _fullName, _phone, _program, _bio, _skills, _interests, _portfolio,
      _github, _linkedin, _location, _availability, _projects,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(StudentProfile p) {
    if (_prefilled) return;
    _prefilled = true;
    _fullName.text = p.fullName;
    _phone.text = p.phone;
    _program.text = p.program;
    _bio.text = p.bio;
    _skills.text = p.skills.join(', ');
    _interests.text = p.interests.join(', ');
    _portfolio.text = p.portfolioUrl;
    _github.text = p.githubUrl;
    _linkedin.text = p.linkedinUrl;
    _location.text = p.location;
    _availability.text = p.availability;
    _projects.text = p.projects.join('\n');
    _year = p.yearOfStudy;
    _categories = p.preferredCategories.toSet();
    _photoUrl = p.photoUrl;
    _resumeUrl = p.resumeUrl;
  }

  List<String> _csv(TextEditingController c) => c.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final uid = ref.read(currentUserProvider)!.uid;
    final res = await ref
        .read(profileRepositoryProvider)
        .uploadStudentPhoto(uid, bytes, picked.name ?? 'photo.png');
    if (!mounted) return;
    res.when(
      success: (url) => setState(() => _photoUrl = url),
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  Future<void> _pickResume() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedResumeExtensions,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.length > AppConstants.maxResumeSizeBytes) {
      if (mounted) context.showSnack('Resume must be under 5 MB.', error: true);
      return;
    }
    final uid = ref.read(currentUserProvider)!.uid;
    final res = await ref.read(profileRepositoryProvider).uploadResume(
          uid,
          file.bytes!,
          file.name,
        );
    if (!mounted) return;
    res.when(
      success: (url) => setState(() => _resumeUrl = url),
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  Future<void> _save(StudentProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = StudentProfile(
      uid: current.uid,
      email: current.email,
      fullName: _fullName.text.trim(),
      photoUrl: _photoUrl,
      phone: _phone.text.trim(),
      program: _program.text.trim(),
      yearOfStudy: _year,
      bio: _bio.text.trim(),
      skills: _csv(_skills),
      interests: _csv(_interests),
      preferredCategories: _categories.toList(),
      portfolioUrl: _portfolio.text.trim(),
      githubUrl: _github.text.trim(),
      linkedinUrl: _linkedin.text.trim(),
      resumeUrl: _resumeUrl,
      certificates: current.certificates,
      projects: _projects.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      location: _location.text.trim(),
      availability: _availability.text.trim(),
    );
    final res = await ref.read(profileRepositoryProvider).saveStudent(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    res.when(
      success: (_) {
        context.showSnack('Profile saved.');
        context.pop();
      },
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myStudentProfileProvider);
    final profile = async.value;
    if (profile != null) _prefill(profile);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                      url: _photoUrl, name: _fullName.text, radius: 48),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      iconSize: 18,
                      icon: const Icon(Icons.camera_alt_rounded),
                      onPressed: _pickPhoto,
                      tooltip: 'Change photo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Full name',
              controller: _fullName,
              validator: (v) => Validators.required(v, 'Full name'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Phone',
              controller: _phone,
              validator: Validators.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Program', controller: _program),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child:
                      Text('Year of study', style: context.text.labelLarge),
                ),
                DropdownButtonFormField<int>(
                  value: _year,
                  items: [1, 2, 3, 4, 5]
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('Year $y')))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v ?? 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Biography',
              controller: _bio,
              maxLines: 4,
              validator: (v) => Validators.maxLen(v, 600),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Skills (comma separated)',
              controller: _skills,
              hint: 'Flutter, Firebase, Figma',
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Interests (comma separated)',
              controller: _interests,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('Preferred internship categories',
                  style: context.text.labelLarge),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.internshipCategories
                  .map(
                    (c) => FilterChip(
                      label: Text(c),
                      selected: _categories.contains(c),
                      onSelected: (sel) => setState(() {
                        sel ? _categories.add(c) : _categories.remove(c);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Projects (one per line)',
              controller: _projects,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Portfolio URL',
                controller: _portfolio,
                validator: Validators.url),
            const SizedBox(height: 16),
            AppTextField(
                label: 'GitHub URL',
                controller: _github,
                validator: Validators.url),
            const SizedBox(height: 16),
            AppTextField(
                label: 'LinkedIn URL',
                controller: _linkedin,
                validator: Validators.url),
            const SizedBox(height: 16),
            AppTextField(label: 'Location', controller: _location),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Availability',
              controller: _availability,
              hint: 'e.g. 10 hrs/week, evenings',
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  _resumeUrl == null
                      ? Icons.upload_file_rounded
                      : Icons.picture_as_pdf_rounded,
                  color: context.colors.primary,
                ),
                title: Text(_resumeUrl == null
                    ? 'Upload resume (PDF)'
                    : 'Resume uploaded — tap to replace'),
                onTap: _pickResume,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save profile',
              loading: _saving,
              onPressed: () => _save(profile),
            ),
          ],
        ),
      ),
    );
  }
}
