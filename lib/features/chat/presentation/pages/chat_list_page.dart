import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/room.dart';
import '../providers/chat_providers.dart';
import '../widgets/room_tile.dart';
import 'chat_room_page.dart';

/// Page displaying list of chat rooms
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text('New Group'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: roomsAsync.when(
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
                'Failed to load chats',
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
                onPressed: () => ref.invalidate(roomsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
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
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation with someone!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(roomsStreamProvider);
            },
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return RoomTile(
                  room: room,
                  onTap: () => _navigateToChat(context, ref, room),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        child: const Icon(Icons.chat),
      ),
    );
  }

  void _navigateToChat(BuildContext context, WidgetRef ref, Room room) {
    // Set current room for state management
    ref.read(currentRoomProvider.notifier).state = room.id;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(room: room),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search coming soon!')),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'new_group':
        // TODO: Implement new group creation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Group coming soon!')),
        );
        break;
      case 'settings':
        // TODO: Navigate to settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
    }
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('New Direct Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show user selection for direct message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User selection coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show group creation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group creation coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}