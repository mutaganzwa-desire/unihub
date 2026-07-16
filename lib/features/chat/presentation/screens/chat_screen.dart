import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/chat_entities.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
  });

  final String conversationId;
  final String peerName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  Timer? _typingTimer;
  bool _typingSent = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_markRead);
  }

  void _markRead() {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      ref
          .read(chatRepositoryProvider)
          .markConversationRead(widget.conversationId, uid);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      ref
          .read(chatRepositoryProvider)
          .setTyping(widget.conversationId, uid, false);
    }
    _input.dispose();
    super.dispose();
  }

  void _onTyping(String _) {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final repo = ref.read(chatRepositoryProvider);
    if (!_typingSent) {
      _typingSent = true;
      repo.setTyping(widget.conversationId, uid, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _typingSent = false;
      repo.setTyping(widget.conversationId, uid, false);
    });
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    _input.clear();
    final res = await ref.read(chatRepositoryProvider).sendText(
          conversationId: widget.conversationId,
          senderId: me.uid,
          senderName: me.displayName,
          text: text,
        );
    final f = res.failureOrNull;
    if (f != null && mounted) context.showSnack(f.message, error: true);
  }

  Future<void> _sendAttachment({required bool image}) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    Uint8List? bytes;
    String? name;
    if (image) {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        bytes = await picked.readAsBytes();
        name = picked.name;
      }
    } else {
      final picked = await FilePicker.platform.pickFiles(withData: true);
      final file = picked?.files.single;
      if (file != null) {
        bytes = file.bytes;
        name = file.name;
      }
    }
    if (bytes == null || name == null) return;
    final res = await ref.read(chatRepositoryProvider).sendAttachment(
          conversationId: widget.conversationId,
          senderId: me.uid,
          senderName: me.displayName,
          bytes: bytes,
          fileName: name,
          isImage: image,
        );
    final f = res.failureOrNull;
    if (f != null && mounted) context.showSnack(f.message, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentUserProvider)?.uid ?? '';
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final conversation =
        ref.watch(conversationProvider(widget.conversationId)).value;
    final peerTyping = conversation?.peerIsTyping(myUid) ?? false;

    // New incoming messages while the screen is open => mark read.
    ref.listen(messagesProvider(widget.conversationId), (_, __) => _markRead());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName),
            if (peerTyping)
              Text('typing…',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.primary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load messages',
                message: e.toString(),
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.waving_hand_rounded,
                      title: 'Say hello!',
                      message: 'Start the conversation below.',
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _MessageBubble(
                        message: items[i],
                        isMine: items[i].senderId == myUid,
                        myUid: myUid,
                      ),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Send image',
                    icon: const Icon(Icons.image_outlined),
                    onPressed: () => _sendAttachment(image: true),
                  ),
                  IconButton(
                    tooltip: 'Send file',
                    icon: const Icon(Icons.attach_file_rounded),
                    onPressed: () => _sendAttachment(image: false),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onChanged: _onTyping,
                      onSubmitted: (_) => _sendText(),
                      textInputAction: TextInputAction.send,
                      decoration:
                          const InputDecoration(hintText: 'Message...'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Send',
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _sendText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.myUid,
  });

  final Message message;
  final bool isMine;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = isMine ? colors.primary : colors.surfaceContainerHighest;
    final fg = isMine ? colors.onPrimary : colors.onSurface;

    Widget content = switch (message.type) {
      MessageType.image => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.attachmentUrl ?? '',
            width: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              width: 200,
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      MessageType.file => InkWell(
          onTap: () {
            final url = message.attachmentUrl;
            if (url != null) {
              launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_rounded, color: fg, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.attachmentName ?? 'File',
                  style: TextStyle(
                      color: fg, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      _ => Text(message.text, style: TextStyle(color: fg)),
    };

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .75),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.sentAt != null)
                  Text(
                    message.sentAt!.time,
                    style: TextStyle(
                        fontSize: 10, color: fg.withOpacity(.7)),
                  ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readByPeer(myUid)
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: fg.withOpacity(.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
