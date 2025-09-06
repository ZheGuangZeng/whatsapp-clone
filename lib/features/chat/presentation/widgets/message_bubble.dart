import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import '../../../file_storage/domain/entities/file_entity.dart';
import '../../../file_storage/presentation/widgets/file_preview_widget.dart';
import '../../../file_storage/presentation/providers/file_providers.dart';

/// Widget representing a message bubble in the chat
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.onReply,
    this.onReact,
  });

  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onReply;
  final Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showAvatar)
              CircleAvatar(
                radius: 12,
                child: Text(
                  message.userId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                ),
              )
            else if (!isMe)
              const SizedBox(width: 24),
              
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reply indicator
                    if (message.isReply)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to message',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Message bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMe ? const Radius.circular(4) : null,
                          bottomLeft: !isMe ? const Radius.circular(4) : null,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message content
                          _buildMessageContent(context, ref),
                          
                          // Message metadata
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                              if (message.isEdited) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 10,
                                  color: isMe
                                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ],
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  _getStatusIcon(message.status),
                                  size: 12,
                                  color: theme.colorScheme.onPrimary.withOpacity(0.7),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Reactions
                    if (message.reactions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          children: message.reactions
                              .map((reaction) => Container(
                                    margin: const EdgeInsets.only(right: 4, top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${reaction.emoji} 1', // TODO: Count reactions
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, WidgetRef ref) {
    // Check if message has file attachment in metadata
    final fileId = message.metadata['file_id'] as String?;
    if (fileId != null) {
      return _buildFileAttachment(context, ref, fileId);
    }

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      
      case MessageType.image:
      case MessageType.video:
      case MessageType.audio:
      case MessageType.file:
        // If we have a file type but no fileId, show placeholder
        return _buildFilePlaceholder(context, message.type);
      
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _buildFileAttachment(BuildContext context, WidgetRef ref, String fileId) {
    final fileCache = ref.watch(fileCacheProvider);
    final cachedFile = fileCache[fileId];

    if (cachedFile != null) {
      return _buildFileContent(context, cachedFile);
    }

    // Load file from repository
    return FutureBuilder<FileEntity?>(
      future: _loadFile(ref, fileId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildFilePlaceholder(context, message.type);
        }

        return _buildFileContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildFileContent(BuildContext context, FileEntity file) {
    switch (file.fileType) {
      case FileType.image:
        return _buildImageContent(context, file);
      case FileType.video:
        return _buildVideoContent(context, file);
      case FileType.audio:
        return _buildAudioContent(context, file);
      case FileType.document:
      case FileType.other:
        return _buildDocumentContent(context, file);
    }
  }

  Widget _buildImageContent(BuildContext context, FileEntity file) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 200,
              maxWidth: 250,
            ),
            child: FilePreviewWidget(
              file: file,
              showFileName: false,
              showFileSize: false,
              showDownloadButton: false,
            ),
          ),
        ),
        if (message.content.isNotEmpty && message.content != file.originalName) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMe
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context, FileEntity file) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 200,
              maxWidth: 250,
            ),
            child: FilePreviewWidget(
              file: file,
              showFileName: false,
              showFileSize: false,
              showDownloadButton: false,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 16),
            const SizedBox(width: 4),
            Text(
              file.formattedSize,
              style: TextStyle(
                fontSize: 12,
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ),
        if (message.content.isNotEmpty && message.content != file.originalName) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMe
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioContent(BuildContext context, FileEntity file) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.originalName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  file.formattedSize,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context, FileEntity file) {
    IconData icon;
    Color iconColor;

    switch (file.extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.originalName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  file.formattedSize,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePlaceholder(BuildContext context, MessageType messageType) {
    IconData icon;
    String label;

    switch (messageType) {
      case MessageType.image:
        icon = Icons.image;
        label = 'Image';
        break;
      case MessageType.video:
        icon = Icons.videocam;
        label = 'Video';
        break;
      case MessageType.audio:
        icon = Icons.audiotrack;
        label = 'Audio';
        break;
      case MessageType.file:
        icon = Icons.attach_file;
        label = 'File';
        break;
      default:
        icon = Icons.insert_drive_file;
        label = 'Attachment';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label (unavailable)',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<FileEntity?> _loadFile(WidgetRef ref, String fileId) async {
    try {
      final fileRepository = ref.read(fileRepositoryProvider);
      final result = await fileRepository.getFileMetadata('', fileId);
      
      return result.fold(
        (failure) => null,
        (file) {
          // Cache the file
          ref.read(fileCacheProvider.notifier).addFile(file);
          return file;
        },
      );
    } catch (e) {
      return null;
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy message content
              },
            ),
            if (onReact != null) ...[
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(context);
                },
              ),
            ],
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Edit message
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Delete message
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    const emojis = ['👍', '❤️', '😂', '😢', '😮', '😡'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('React to message'),
        content: Wrap(
          children: emojis
              .map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReact?.call(emoji);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}