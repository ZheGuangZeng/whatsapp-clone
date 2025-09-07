import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/sources/chat_remote_source.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../../domain/usecases/create_room_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/get_rooms_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

// ========================================
// DATA LAYER PROVIDERS
// ========================================

/// Provider for chat remote data source
final chatRemoteSourceProvider = Provider<ChatRemoteSource>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatRemoteSource(supabase);
});

/// Provider for chat repository
final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  final remoteSource = ref.watch(chatRemoteSourceProvider);
  return ChatRepository(remoteSource);
});

// ========================================
// USE CASE PROVIDERS
// ========================================

/// Provider for send message use case
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendMessageUseCase(repository);
});

/// Provider for get messages use case
final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetMessagesUseCase(repository);
});

/// Provider for mark as read use case
final markMessageAsReadUseCaseProvider = Provider<MarkMessageAsReadUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return MarkMessageAsReadUseCase(repository);
});

/// Provider for mark room as read use case
final markRoomAsReadUseCaseProvider = Provider<MarkRoomAsReadUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return MarkRoomAsReadUseCase(repository);
});

/// Provider for create room use case
final createRoomUseCaseProvider = Provider<CreateRoomUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return CreateRoomUseCase(repository);
});

/// Provider for get or create direct message use case
final getOrCreateDirectMessageUseCaseProvider = Provider<GetOrCreateDirectMessageUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetOrCreateDirectMessageUseCase(repository);
});

/// Provider for get rooms use case
final getRoomsUseCaseProvider = Provider<GetRoomsUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetRoomsUseCase(repository);
});

/// Provider for watch rooms use case
final watchRoomsUseCaseProvider = Provider<WatchRoomsUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return WatchRoomsUseCase(repository);
});

// ========================================
// STATE PROVIDERS
// ========================================

/// Provider for watching all rooms
final roomsStreamProvider = StreamProvider<List<Room>>((ref) {
  final watchRoomsUseCase = ref.watch(watchRoomsUseCaseProvider);
  return watchRoomsUseCase.call();
});

/// Provider for watching messages in a specific room
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchMessages(roomId);
});

/// Provider for watching new messages (for notifications)
final newMessagesStreamProvider = StreamProvider<Message>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchNewMessages();
});

/// Provider for watching typing indicators in a specific room
final typingIndicatorsStreamProvider = StreamProvider.family<List<String>, String>((ref, roomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchTypingIndicators(roomId).map((indicators) =>
      indicators.map((indicator) => indicator.displayName).toList());
});

/// Provider for current room ID (for navigation state)
final currentRoomProvider = StateProvider<String?>((ref) => null);

/// Provider for typing status in current room
final isTypingProvider = StateProvider.family<bool, String>((ref, roomId) => false);

/// Provider for message composition state
final messageCompositionProvider = StateProvider.family<String, String>((ref, roomId) => '');

/// Provider for reply-to message state
final replyToMessageProvider = StateProvider.family<Message?, String>((ref, roomId) => null);

// ========================================
// ASYNC NOTIFIER PROVIDERS
// ========================================

/// Provider for sending message state
final sendMessageProvider = StateNotifierProvider.family<SendMessageNotifier, AsyncValue<void>, String>(
  (ref, roomId) => SendMessageNotifier(
    ref.watch(sendMessageUseCaseProvider),
    roomId,
  ),
);

/// Provider for loading more messages state
final loadMoreMessagesProvider = StateNotifierProvider.family<LoadMoreMessagesNotifier, AsyncValue<List<Message>>, String>(
  (ref, roomId) => LoadMoreMessagesNotifier(
    ref.watch(getMessagesUseCaseProvider),
    roomId,
  ),
);

// ========================================
// NOTIFIER CLASSES
// ========================================

/// Notifier for sending messages
class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  SendMessageNotifier(this._sendMessageUseCase, this.roomId) : super(const AsyncValue.data(null));

  final SendMessageUseCase _sendMessageUseCase;
  final String roomId;

  /// Send a message to the room
  Future<void> sendMessage({
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (content.trim().isEmpty) return;

    state = const AsyncValue.loading();

    final params = SendMessageParams(
      roomId: roomId,
      content: content.trim(),
      type: type,
      replyTo: replyTo,
      metadata: metadata,
    );

    final result = await _sendMessageUseCase.call(params);
    
    result.when(
      success: (_) => state = const AsyncValue.data(null),
      failure: (failure) => state = AsyncValue.error(failure, StackTrace.current),
    );
  }
}

/// Notifier for loading more messages
class LoadMoreMessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  LoadMoreMessagesNotifier(this._getMessagesUseCase, this.roomId) : super(const AsyncValue.data([]));

  final GetMessagesUseCase _getMessagesUseCase;
  final String roomId;
  List<Message> _messages = [];
  bool _hasMore = true;
  bool _isLoading = false;

  /// Load initial messages
  Future<void> loadInitialMessages() async {
    if (_isLoading) return;
    
    _isLoading = true;
    state = const AsyncValue.loading();

    final params = GetMessagesParams(roomId: roomId, limit: 50);
    final result = await _getMessagesUseCase.call(params);

    result.when(
      success: (messages) {
        _messages = messages;
        _hasMore = messages.length >= 50;
        state = AsyncValue.data(List.from(_messages));
      },
      failure: (failure) => state = AsyncValue.error(failure, StackTrace.current),
    );

    _isLoading = false;
  }

  /// Load more older messages
  Future<void> loadMoreMessages() async {
    if (_isLoading || !_hasMore || _messages.isEmpty) return;

    _isLoading = true;

    final params = GetMessagesParams(
      roomId: roomId,
      limit: 50,
      before: _messages.last.id,
    );

    final result = await _getMessagesUseCase.call(params);

    result.when(
      success: (messages) {
        if (messages.isNotEmpty) {
          _messages.addAll(messages);
          _hasMore = messages.length >= 50;
          state = AsyncValue.data(List.from(_messages));
        } else {
          _hasMore = false;
        }
      },
      failure: (failure) {
        // Silently fail for pagination errors, don't affect existing messages
      },
    );

    _isLoading = false;
  }

  /// Check if there are more messages to load
  bool get hasMore => _hasMore;

  /// Check if currently loading
  bool get isLoading => _isLoading;
}