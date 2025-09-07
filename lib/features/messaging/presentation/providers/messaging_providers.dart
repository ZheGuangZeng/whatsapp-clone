import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/message_local_datasource.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/i_message_repository.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Provider for message remote data source
final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MessageRemoteDataSource(supabase);
});

/// Provider for message local data source
final messageLocalDataSourceProvider = Provider<MessageLocalDataSource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return MessageLocalDataSource(sharedPreferences);
});

/// Provider for message repository
final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  final remoteDataSource = ref.watch(messageRemoteDataSourceProvider);
  final localDataSource = ref.watch(messageLocalDataSourceProvider);
  
  return MessageRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

/// Provider for user rooms list
final userRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  final result = await repository.getUserRooms();
  
  return result.when(
    success: (rooms) => rooms,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// Provider for messages stream for a specific room
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.messagesStream(roomId);
});

/// Provider for typing indicators stream for a room
final typingIndicatorsProvider = StreamProvider.family<List<TypingIndicator>, String>((ref, roomId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.typingIndicatorsStream(roomId);
});

/// Provider for user presence stream
final presenceStreamProvider = StreamProvider<List<UserPresence>>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.presenceStream();
});

/// Provider for sending messages
final sendMessageProvider = Provider<Future<void> Function(Message)>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return (Message message) async {
    final result = await repository.sendMessage(message);
    result.when(
      success: (_) {}, // Success handled by stream updates
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// Provider for marking messages as read
final markAsReadProvider = Provider<Future<void> Function(String, List<String>)>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return (String roomId, List<String> messageIds) async {
    final result = await repository.markAsRead(roomId, messageIds);
    result.when(
      success: (_) {},
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// Provider for setting typing status
final setTypingProvider = Provider<Future<void> Function(String, bool)>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return (String roomId, bool isTyping) async {
    final result = await repository.setTyping(roomId, isTyping);
    result.when(
      success: (_) {},
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// Provider for updating presence
final updatePresenceProvider = Provider<Future<void> Function(bool, PresenceStatus)>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return (bool isOnline, PresenceStatus status) async {
    final result = await repository.updatePresence(isOnline, status);
    result.when(
      success: (_) {},
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// Provider for creating direct rooms
final createDirectRoomProvider = Provider<Future<Room> Function(String)>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return (String otherUserId) async {
    final result = await repository.getOrCreateDirectRoom(otherUserId);
    return result.when(
      success: (room) => room,
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// Provider for creating group rooms
final createGroupRoomProvider = Provider<Future<Room> Function(String, List<String>)>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return (String name, List<String> participantIds) async {
    final result = await repository.createGroupRoom(name, participantIds);
    return result.when(
      success: (room) => room,
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// Provider for syncing offline messages
final syncOfflineMessagesProvider = Provider<Future<void> Function()>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  
  return () async {
    final result = await repository.syncOfflineMessages();
    result.when(
      success: (_) {},
      failure: (failure) => throw Exception(failure.message),
    );
  };
});

/// State notifier for managing current room
class CurrentRoomNotifier extends StateNotifier<String?> {
  CurrentRoomNotifier() : super(null);
  
  void setCurrentRoom(String? roomId) {
    state = roomId;
  }
  
  void clearCurrentRoom() {
    state = null;
  }
}

/// Provider for current room state
final currentRoomProvider = StateNotifierProvider<CurrentRoomNotifier, String?>((ref) {
  return CurrentRoomNotifier();
});

/// State notifier for managing typing status per room
class TypingStatusNotifier extends StateNotifier<Map<String, bool>> {
  TypingStatusNotifier() : super({});
  
  void setTyping(String roomId, bool isTyping) {
    state = {...state, roomId: isTyping};
  }
  
  void clearTyping(String roomId) {
    final newState = Map<String, bool>.from(state);
    newState.remove(roomId);
    state = newState;
  }
}

/// Provider for typing status state
final typingStatusProvider = StateNotifierProvider<TypingStatusNotifier, Map<String, bool>>((ref) {
  return TypingStatusNotifier();
});

/// State notifier for managing online status
class OnlineStatusNotifier extends StateNotifier<bool> {
  OnlineStatusNotifier(this._ref) : super(false) {
    _initialize();
  }
  
  final Ref _ref;
  
  void _initialize() {
    // Set initial online status
    setOnline(true);
  }
  
  void setOnline(bool isOnline) {
    if (state != isOnline) {
      state = isOnline;
      // Update presence in repository
      final updatePresence = _ref.read(updatePresenceProvider);
      updatePresence(isOnline, PresenceStatus.available).catchError((_) {});
      
      // Sync offline messages when coming online
      if (isOnline) {
        final syncOfflineMessages = _ref.read(syncOfflineMessagesProvider);
        syncOfflineMessages().catchError((_) {});
      }
    }
  }
}

/// Provider for online status
final onlineStatusProvider = StateNotifierProvider<OnlineStatusNotifier, bool>((ref) {
  return OnlineStatusNotifier(ref);
});