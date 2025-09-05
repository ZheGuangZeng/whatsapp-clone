import 'package:flutter/material.dart';

import '../../domain/entities/room.dart';

/// Widget representing a room tile in the chat list
class RoomTile extends StatelessWidget {
  const RoomTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: room.avatarUrl != null
            ? NetworkImage(room.avatarUrl!)
            : null,
        child: room.avatarUrl == null
            ? Text(
                _getAvatarText(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        _getRoomName(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.lastMessage != null) ...[
            Text(
              _getLastMessageText(),
              style: TextStyle(
                color: room.hasUnreadMessages
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: room.hasUnreadMessages
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Text(
              room.isGroupChat ? 'No messages yet' : 'Start conversation',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (room.isGroupChat && room.activeParticipants.isNotEmpty)
            Text(
              '${room.activeParticipants.length} members',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageAt != null)
            Text(
              _formatTimestamp(room.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: room.hasUnreadMessages
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: room.hasUnreadMessages
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 4),
          if (room.hasUnreadMessages)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _getAvatarText() {
    if (room.isGroupChat && room.name != null) {
      return room.name!.substring(0, 1).toUpperCase();
    }
    
    // For direct messages, we'd need current user context
    // For now, use room ID first character
    return room.id.substring(0, 1).toUpperCase();
  }

  String _getRoomName() {
    if (room.isGroupChat && room.name != null) {
      return room.name!;
    }
    
    // For direct messages, we'd need to get the other participant's name
    // For now, return a placeholder
    return room.name ?? 'Direct Message';
  }

  String _getLastMessageText() {
    if (room.lastMessage == null) return '';
    
    final message = room.lastMessage!;
    
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📄 Document';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.system:
        return message.content;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}