import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/startup_profile.dart';
import '../providers/profile_providers.dart';

/// Verification request workflow: pick documents, add a note, submit.
/// Status flips to `pending`; only an admin can set verified/rejected.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _note = TextEditingController();
  final List<Uint8List> _files = [];
  final List<String> _fileNames = [];
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true,
        withData: true);
    if (result == null) return;
    setState(() {
      for (final file in result.files) {
        if (file.bytes != null) {
          _files.add(file.bytes!);
          _fileNames.add(file.name);
        }
      }
    });
  }

  Future<void> _submit(StartupProfile startup) async {
    if (_files.isEmpty) {
      context.showSnack('Attach at least one document.', error: true);
      return;
    }
    setState(() => _submitting = true);
    final res =
        await ref.read(profileRepositoryProvider).submitVerificationRequest(
              startup: startup,
              documents: _files,
              documentNames: _fileNames,
              note: _note.text.trim(),
            );
    if (!mounted) return;
    setState(() => _submitting = false);
    res.when(
      success: (_) {
        context.showSnack('Verification request submitted.');
        setState(_files.clear);
      },
      failure: (f) => context.showSnack(f.message, error: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(myStartupProfileProvider).value;
    if (startup == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = startup.verificationStatus;
    final (icon, title, body) = switch (status) {
      VerificationStatus.verified => (
          Icons.verified_rounded,
          'You are verified',
          'Your startup carries the verified badge and can post internships.'
        ),
      VerificationStatus.pending => (
          Icons.hourglass_top_rounded,
          'Under review',
          'An administrator is reviewing your documents. You will be notified once a decision is made.'
        ),
      VerificationStatus.rejected => (
          Icons.error_outline_rounded,
          'Request rejected',
          'Your previous request was rejected. Review your documents and submit again.'
        ),
      _ => (
          Icons.verified_outlined,
          'Get verified',
          'Upload a registration certificate, university incubation letter, or similar proof that your startup is real. Verified startups get a badge and can post internships.'
        ),
    };

    final canSubmit = status == VerificationStatus.unverified ||
        status == VerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(icon, size: 64, color: context.colors.primary),
          const SizedBox(height: 16),
          Text(title,
              style: context.text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          if (canSubmit) ...[
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: Text(_files.isEmpty
                    ? 'Attach documents'
                    : '${_files.length} document(s) attached'),
                trailing: const Icon(Icons.add_rounded),
                onTap: _pickFiles,
              ),
            ),
            ...List.generate(_files.length, (index) {
              final name = _fileNames[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.description_outlined),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _files.removeAt(index);
                    _fileNames.removeAt(index);
                  }),
                ),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Note for the reviewer (optional)',
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Submit for review',
              loading: _submitting,
              onPressed: () => _submit(startup),
            ),
          ],
        ],
      ),
    );
  }
}
