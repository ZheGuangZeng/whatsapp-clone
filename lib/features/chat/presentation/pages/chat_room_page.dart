import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/room.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

/// Page for individual chat room
class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _scrollController = ScrollController();
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    
    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Load initial messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loadMoreMessagesProvider(widget.room.id).notifier).loadInitialMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    
    // Clear current room when leaving
    ref.read(currentRoomProvider.notifier).state = null;
    
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more messages when near the end
      ref.read(loadMoreMessagesProvider(widget.room.id).notifier).loadMoreMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.room.id));
    final authState = ref.watch(authNotifierProvider);
    
    // Get current user ID from auth state
    if (authState.user != null) {
      _currentUserId = authState.user!.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.room.getAvatarUrl(_currentUserId) != null
                  ? NetworkImage(widget.room.getAvatarUrl(_currentUserId)!)
                  : null,
              child: widget.room.getAvatarUrl(_currentUserId) == null
                  ? Text(
                      widget.room.getDisplayName(_currentUserId).substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.getDisplayName(_currentUserId),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.room.isGroupChat)
                    Text(
                      '${widget.room.activeParticipants.length} members',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _startVideoCall(context),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startVoiceCall(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_info',
                child: Text('View Info'),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Text('Search'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute'),
              ),
              if (widget.room.isGroupChat) ...[
                const PopupMenuItem(
                  value: 'add_participant',
                  child: Text('Add Participant'),
                ),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load messages',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(messagesStreamProvider(widget.room.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest messages at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.userId == _currentUserId;
                    final showAvatar = !isMe && widget.room.isGroupChat;
                    
                    // Show timestamp if it's been more than 5 minutes since last message
                    final showTimestamp = index == messages.length - 1 ||
                        (index < messages.length - 1 &&
                            messages[index + 1].createdAt.difference(message.createdAt).inMinutes > 5);

                    return Column(
                      children: [
                        if (showTimestamp)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatTimestamp(message.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          onReply: () => _replyToMessage(message),
                          onReact: (emoji) => _reactToMessage(message.id, emoji),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // Typing indicator
          TypingIndicator(roomId: widget.room.id),
          
          // Message input
          MessageInput(
            roomId: widget.room.id,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  void _sendMessage(String content, {String? replyToId}) {
    ref.read(sendMessageProvider(widget.room.id).notifier).sendMessage(
          content: content,
          replyTo: replyToId,
        );
  }

  void _replyToMessage(message) {
    // Set reply-to state
    ref.read(replyToMessageProvider(widget.room.id).notifier).state = message;
  }

  void _reactToMessage(String messageId, String emoji) {
    ref.read(chatRepositoryProvider).addReaction(messageId, emoji);
  }

  void _startVideoCall(BuildContext context) {
    // TODO: Implement video call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video call coming soon!')),
    );
  }

  void _startVoiceCall(BuildContext context) {
    // TODO: Implement voice call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice call coming soon!')),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'view_info':
        // TODO: Show room info
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room info coming soon!')),
        );
        break;
      case 'search':
        // TODO: Show search in chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search in chat coming soon!')),
        );
        break;
      case 'mute':
        // TODO: Mute/unmute chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mute functionality coming soon!')),
        );
        break;
      case 'add_participant':
        // TODO: Add participant to group
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add participant coming soon!')),
        );
        break;
    }
  }
}