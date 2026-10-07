import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  final fb.User currentUser;
  final ChatUser otherUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _pendingMessages = <MessageModel>[];
  final _updatingStatuses = <String>{};
  late final Stream<List<MessageModel>> _messages;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = _chatService.watchMessages(widget.otherUser.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    final pending = MessageModel.pending(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      senderId: widget.currentUser.uid,
      senderEmail: widget.currentUser.email ?? '',
      receiverId: widget.otherUser.id,
      message: text,
    );
    setState(() {
      _sending = true;
      _pendingMessages.insert(0, pending);
      _messageController.clear();
    });

    try {
      await _chatService.sendMessage(
        recipient: widget.otherUser,
        message: text,
      );
      if (!mounted) return;
      setState(
        () =>
            _pendingMessages.removeWhere((message) => message.id == pending.id),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _pendingMessages.removeWhere((message) => message.id == pending.id),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message could not be sent: $error')),
      );
      _messageController.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _updateIncomingStatuses(List<MessageModel> messages) {
    for (final message in messages) {
      if (message.status == 'seen' ||
          message.receiverId != widget.currentUser.uid ||
          !_updatingStatuses.add(message.id)) {
        continue;
      }
      unawaited(_markDeliveredThenSeen(message));
    }
  }

  Future<void> _markDeliveredThenSeen(MessageModel message) async {
    try {
      if (message.status == 'sent') {
        await _chatService.updateMessageStatus(
          otherUserId: widget.otherUser.id,
          messageId: message.id,
          status: 'delivered',
        );
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (!mounted) return;
      await _chatService.updateMessageStatus(
        otherUserId: widget.otherUser.id,
        messageId: message.id,
        status: 'seen',
      );
    } catch (_) {
      // Keep the message visible even if the status update is denied or offline.
    } finally {
      _updatingStatuses.remove(message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19.r,
              backgroundImage: widget.otherUser.image.isEmpty
                  ? null
                  : NetworkImage(widget.otherUser.image),
              child: widget.otherUser.image.isEmpty
                  ? Text(
                      widget.otherUser.displayName
                          .substring(0, 1)
                          .toUpperCase(),
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherUser.email,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Could not load this conversation. Check your connection and Firestore rules.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = [..._pendingMessages, ...snapshot.data!];
                _updateIncomingStatuses(snapshot.data!);
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Say hello to start the conversation.'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 18.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _animatedBubble(message);
                  },
                );
              },
            ),
          ),
          _composer(context),
        ],
      ),
    );
  }

  Widget _animatedBubble(MessageModel message) {
    final mine = message.senderId == widget.currentUser.uid;
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = mine
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = mine
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      key: ValueKey(message.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(mine ? 18 * (1 - value) : -18 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: 0.78.sw),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 12.w, 8.h),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(mine ? 18.r : 5.r),
              bottomRight: Radius.circular(mine ? 5.r : 18.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.message,
                  style: TextStyle(color: foregroundColor, fontSize: 15.sp),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TimeOfDay.fromDateTime(message.timestamp).format(context),
                    style: TextStyle(
                      color: foregroundColor.withValues(alpha: .7),
                      fontSize: 10.sp,
                    ),
                  ),
                  if (mine) ...[
                    SizedBox(width: 4.w),
                    _statusIndicator(message.status, foregroundColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(String status, Color color) {
    if (status == 'sending') {
      return Text(
        'Sending...',
        style: TextStyle(color: color.withValues(alpha: .75), fontSize: 10.sp),
      );
    }
    if (status == 'seen') {
      return Icon(
        Icons.done_all,
        size: 14.r,
        color: Colors.lightBlueAccent.shade100,
      );
    }
    if (status == 'delivered') {
      return Icon(
        Icons.done_all,
        size: 14.r,
        color: color.withValues(alpha: .8),
      );
    }
    return Icon(Icons.check, size: 14.r, color: color.withValues(alpha: .8));
  }

  Widget _composer(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Message',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 48.r,
            width: 48.r,
            child: IconButton.filled(
              onPressed: _sending ? null : _sendMessage,
              tooltip: _sending ? 'Sending message' : 'Send message',
              icon: _sending
                  ? SizedBox.square(
                      dimension: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}
