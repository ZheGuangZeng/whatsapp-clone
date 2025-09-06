import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../providers/chat_providers.dart';
import '../../../file_storage/presentation/widgets/file_picker_widget.dart';
import '../../../file_storage/presentation/providers/file_providers.dart';
import '../../../file_storage/domain/entities/file_entity.dart';
import '../../../file_storage/domain/usecases/upload_file_usecase.dart';
import '../../../../core/constants/app_constants.dart';

/// Widget for composing and sending messages
class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({
    super.key,
    required this.roomId,
    required this.onSendMessage,
  });

  final String roomId;
  final Function(String content, {String? replyToId, FileEntity? fileAttachment}) onSendMessage;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _controller.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      
      // Update message composition state
      ref.read(messageCompositionProvider(widget.roomId).notifier).state = _controller.text;
      
      // Handle typing indicators
      if (isComposing) {
        ref.read(chatRepositoryProvider).startTyping(widget.roomId);
        ref.read(isTypingProvider(widget.roomId).notifier).state = true;
      } else {
        ref.read(chatRepositoryProvider).stopTyping(widget.roomId);
        ref.read(isTypingProvider(widget.roomId).notifier).state = false;
      }
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _isComposing) {
      // Stop typing when losing focus
      ref.read(chatRepositoryProvider).stopTyping(widget.roomId);
      ref.read(isTypingProvider(widget.roomId).notifier).state = false;
    }
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final replyToMessage = ref.read(replyToMessageProvider(widget.roomId));
    
    // Send the message
    widget.onSendMessage(content, replyToId: replyToMessage?.id);
    
    // Clear input and states
    _controller.clear();
    ref.read(messageCompositionProvider(widget.roomId).notifier).state = '';
    ref.read(replyToMessageProvider(widget.roomId).notifier).state = null;
    ref.read(chatRepositoryProvider).stopTyping(widget.roomId);
    ref.read(isTypingProvider(widget.roomId).notifier).state = false;
    
    setState(() {
      _isComposing = false;
    });
  }

  void _cancelReply() {
    ref.read(replyToMessageProvider(widget.roomId).notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final replyToMessage = ref.watch(replyToMessageProvider(widget.roomId));
    final sendingState = ref.watch(sendMessageProvider(widget.roomId));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reply preview
          if (replyToMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to message',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          replyToMessage.content,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelReply,
                    icon: const Icon(Icons.close, size: 18),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: () => _showAttachmentOptions(context),
                  icon: const Icon(Icons.attach_file),
                ),
                
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            maxLines: 5,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        if (!_isComposing)
                          IconButton(
                            onPressed: () => _showEmojiPicker(context),
                            icon: const Icon(Icons.emoji_emotions_outlined),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send/voice button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: sendingState.isLoading ? null : (_isComposing ? _sendMessage : _startVoiceRecording),
                    icon: sendingState.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            _isComposing ? Icons.send : Icons.mic,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  onTap: () {
                    Navigator.pop(context);
                    _shareLocation();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.person,
                  label: 'Contact',
                  onTap: () {
                    Navigator.pop(context);
                    _shareContact();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.poll,
                  label: 'Poll',
                  onTap: () {
                    Navigator.pop(context);
                    _createPoll();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    // TODO: Implement emoji picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emoji picker coming soon!')),
    );
  }

  void _startVoiceRecording() {
    // TODO: Implement voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recording coming soon!')),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _uploadAndSendFile(File(image.path));
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        await _uploadAndSendFile(File(image.path));
      }
    } catch (e) {
      _showError('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedDocumentTypes,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _uploadAndSendFile(File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Failed to pick document: ${e.toString()}');
    }
  }

  /// Upload file and send as message
  Future<void> _uploadAndSendFile(File file) async {
    try {
      // Show upload dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Uploading File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while your file is being uploaded...'),
            ],
          ),
        ),
      );

      final uploadFileUseCase = ref.read(uploadFileUseCaseProvider);
      final result = await uploadFileUseCase(UploadFileParams(
        file: file,
        bucket: AppConstants.chatMediaBucket,
        compressionQuality: 80,
        generateThumbnail: true,
      ));

      // Close upload dialog
      Navigator.of(context).pop();

      result.fold(
        (failure) {
          _showError('Upload failed: ${failure.toString()}');
        },
        (fileEntity) {
          // Send message with file attachment
          final fileName = fileEntity.originalName;
          widget.onSendMessage(
            fileName, // Use filename as message content
            fileAttachment: fileEntity,
          );

          _showSuccess('File uploaded successfully');
        },
      );
    } catch (e) {
      // Close upload dialog if still open
      Navigator.of(context).pop();
      _showError('Upload error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing coming soon!')),
    );
  }

  void _shareContact() {
    // TODO: Implement contact sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact sharing coming soon!')),
    );
  }

  void _createPoll() {
    // TODO: Implement poll creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll creation coming soon!')),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}