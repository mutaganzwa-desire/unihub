import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/application.dart';
import '../providers/application_providers.dart';
import '../widgets/status_timeline.dart';

/// Startup view of a single application: applicant profile, motivation,
/// attachments, decision actions and a "message applicant" shortcut.
class ApplicantDetailsScreen extends ConsumerWidget {
  const ApplicantDetailsScreen({super.key, required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicationProvider(applicationId));
    final isStartup = ref.watch(currentUserProvider)?.isStartup ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Application')),
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(applicationProvider(applicationId)),
        builder: (a) {
          if (a == null) {
            return const EmptyState(
                icon: Icons.link_off_rounded,
                title: 'Application not found');
          }
          return _Body(application: a, isStartup: isStartup);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.application, required this.isStartup});
  final Application application;
  final bool isStartup;

  Future<void> _open(BuildContext context, String? url) async {
    if (url == null) return;
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      context.showSnack('Could not open the file.', error: true);
    }
  }

  Future<void> _decide(BuildContext context, WidgetRef ref,
      ApplicationStatus status) async {
    final res = await ref
        .read(applicationRepositoryProvider)
        .updateStatus(application, status);
    if (context.mounted) {
      context.showSnack(
        res.isSuccess
            ? 'Status updated to ${status.label}.'
            : res.failureOrNull!.message,
        error: !res.isSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentProfile =
        ref.watch(studentProfileProvider(application.studentId)).value;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            UserAvatar(
                url: application.studentPhotoUrl,
                name: application.studentName,
                radius: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(application.studentName,
                      style: context.text.titleLarge),
                  Text(application.internshipTitle,
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.primary)),
                ],
              ),
            ),
            StatusChip(
                status: application.status.name,
                label: application.status.label),
          ],
        ),
        if (studentProfile != null) ...[
          const SizedBox(height: 12),
          if (studentProfile.program.isNotEmpty)
            Text(
                '${studentProfile.program} • Year ${studentProfile.yearOfStudy}'),
          if (studentProfile.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: studentProfile.skills
                  .take(8)
                  .map((s) => Chip(label: Text(s)))
                  .toList(),
            ),
          ],
        ],
        const SizedBox(height: 20),
        Text('Motivation', style: context.text.titleMedium),
        const SizedBox(height: 8),
        Text(application.motivation.isEmpty
            ? '—'
            : application.motivation),
        const SizedBox(height: 20),
        if (application.resumeUrl != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf_rounded,
                  color: context.colors.primary),
              title: const Text('Resume'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _open(context, application.resumeUrl),
            ),
          ),
        if (application.coverLetterUrl != null) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.description_outlined,
                  color: context.colors.primary),
              title: const Text('Cover letter'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _open(context, application.coverLetterUrl),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Timeline', style: context.text.titleMedium),
        const SizedBox(height: 12),
        StatusTimeline(timeline: application.timeline),
        if (isStartup) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message applicant'),
            onPressed: () => openConversationWith(
              context,
              ref,
              peerId: application.studentId,
              peerName: application.studentName,
              peerPhotoUrl: application.studentPhotoUrl,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: () =>
                    _decide(context, ref, ApplicationStatus.underReview),
                child: const Text('Under review'),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    _decide(context, ref, ApplicationStatus.shortlisted),
                child: const Text('Shortlist'),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    _decide(context, ref, ApplicationStatus.interview),
                child: const Text('Interview'),
              ),
              FilledButton(
                onPressed: () =>
                    _decide(context, ref, ApplicationStatus.accepted),
                child: const Text('Accept'),
              ),
              OutlinedButton(
                onPressed: () =>
                    _decide(context, ref, ApplicationStatus.rejected),
                child: const Text('Reject'),
              ),
              TextButton(
                onPressed: () =>
                    _decide(context, ref, ApplicationStatus.archived),
                child: const Text('Archive'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
