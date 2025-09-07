import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/room.dart';

/// Page for individual chat room
class ChatRoomPage extends ConsumerWidget {
  const ChatRoomPage({super.key, this.room});

  /// Factory constructor for creating ChatRoomPage from room ID
  factory ChatRoomPage.fromId(String roomId) {
    return const ChatRoomPage(room: null);
  }

  final Room? room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room?.name ?? 'Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Voice call
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Start the conversation!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}