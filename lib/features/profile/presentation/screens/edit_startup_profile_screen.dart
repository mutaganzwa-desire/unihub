import 'dart:typed_data';

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
import '../../domain/entities/startup_profile.dart';
import '../providers/profile_providers.dart';

class EditStartupProfileScreen extends ConsumerStatefulWidget {
  const EditStartupProfileScreen({super.key});

  @override
  ConsumerState<EditStartupProfileScreen> createState() =>
      _EditStartupProfileScreenState();
}

class _EditStartupProfileScreenState
    extends ConsumerState<EditStartupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _founder = TextEditingController();
  final _description = TextEditingController();
  final _mission = TextEditingController();
  final _vision = TextEditingController();
  final _industry = TextEditingController();
  final _website = TextEditingController();
  final _phone = TextEditingController();
  final _office = TextEditingController();
  final _linkedin = TextEditingController();
  final _twitter = TextEditingController();
  final _instagram = TextEditingController();

  String _companySize = AppConstants.companySizes.first;
  String _fundingStage = AppConstants.fundingStages.first;
  String? _logoUrl;
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name, _founder, _description, _mission, _vision, _industry, _website,
      _phone, _office, _linkedin, _twitter, _instagram,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(StartupProfile p) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = p.name;
    _founder.text = p.founder;
    _description.text = p.description;
    _mission.text = p.mission;
    _vision.text = p.vision;
    _industry.text = p.industry;
    _website.text = p.website;
    _phone.text = p.phone;
    _office.text = p.officeLocation;
    _linkedin.text = p.socialLinks['linkedin'] ?? '';
    _twitter.text = p.socialLinks['twitter'] ?? '';
    _instagram.text = p.socialLinks['instagram'] ?? '';
    if (p.companySize.isNotEmpty) _companySize = p.companySize;
    if (p.fundingStage.isNotEmpty) _fundingStage = p.fundingStage;
    _logoUrl = p.logoUrl;
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final uid = ref.read(currentUserProvider)!.uid;
    final res = await ref.read(profileRepositoryProvider).uploadStartupLogo(
          uid,
          bytes,
          picked.name ?? 'logo.png',
        );
    if (!mounted) return;
    res.when(
      success: (url) => setState(() => _logoUrl = url),
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  Future<void> _save(StartupProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final links = {
      if (_linkedin.text.trim().isNotEmpty) 'linkedin': _linkedin.text.trim(),
      if (_twitter.text.trim().isNotEmpty) 'twitter': _twitter.text.trim(),
      if (_instagram.text.trim().isNotEmpty)
        'instagram': _instagram.text.trim(),
    };
    final updated = StartupProfile(
      uid: current.uid,
      email: current.email,
      name: _name.text.trim(),
      logoUrl: _logoUrl,
      founder: _founder.text.trim(),
      description: _description.text.trim(),
      mission: _mission.text.trim(),
      vision: _vision.text.trim(),
      industry: _industry.text.trim(),
      website: _website.text.trim(),
      phone: _phone.text.trim(),
      officeLocation: _office.text.trim(),
      socialLinks: links,
      companySize: _companySize,
      fundingStage: _fundingStage,
      verificationStatus: current.verificationStatus,
      documents: current.documents,
    );
    final res = await ref.read(profileRepositoryProvider).saveStartup(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    res.when(
      success: (_) {
        context.showSnack('Startup profile saved.');
        context.pop();
      },
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myStartupProfileProvider).value;
    if (profile != null) _prefill(profile);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit startup')),
        body: const Center(child: CircularProgressIndicator()),
      );
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
      appBar: AppBar(title: const Text('Edit startup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(url: _logoUrl, name: _name.text, radius: 48),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      iconSize: 18,
                      icon: const Icon(Icons.camera_alt_rounded),
                      onPressed: _pickLogo,
                      tooltip: 'Change logo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
                label: 'Startup name',
                controller: _name,
                validator: (v) => Validators.required(v, 'Name')),
            const SizedBox(height: 16),
            AppTextField(label: 'Founder', controller: _founder),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Description', controller: _description, maxLines: 4),
            const SizedBox(height: 16),
            AppTextField(label: 'Mission', controller: _mission, maxLines: 2),
            const SizedBox(height: 16),
            AppTextField(label: 'Vision', controller: _vision, maxLines: 2),
            const SizedBox(height: 16),
            AppTextField(label: 'Industry', controller: _industry),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Website',
                controller: _website,
                validator: Validators.url),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Phone',
                controller: _phone,
                validator: Validators.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            AppTextField(label: 'Office location', controller: _office),
            const SizedBox(height: 16),
            dropdown('Company size', AppConstants.companySizes, _companySize,
                (v) => _companySize = v),
            dropdown('Funding stage', AppConstants.fundingStages,
                _fundingStage, (v) => _fundingStage = v),
            AppTextField(
                label: 'LinkedIn',
                controller: _linkedin,
                validator: Validators.url),
            const SizedBox(height: 16),
            AppTextField(
                label: 'X / Twitter',
                controller: _twitter,
                validator: Validators.url),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Instagram',
                controller: _instagram,
                validator: Validators.url),
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
