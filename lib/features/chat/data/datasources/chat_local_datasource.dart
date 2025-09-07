import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message_model.dart';
import '../models/room_model.dart';
import '../models/message_thread_model.dart';

/// Local data source for chat data using SharedPreferences for caching
class ChatLocalDataSource {
  const ChatLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _messagesPrefix = 'chat_messages_';
  static const String _roomsPrefix = 'chat_rooms_';
  static const String _threadsPrefix = 'chat_threads_';
  static const String _lastSyncPrefix = 'last_sync_';

  /// Cache messages for a room
  Future<void> cacheMessages({
    required String roomId,
    required List<ChatMessageModel> messages,
  }) async {
    final messagesList = messages.map((m) => m.toJson()).toList();
    await _prefs.setString(
      '$_messagesPrefix$roomId',
      jsonEncode(messagesList),
    );
    await _updateLastSync(roomId);
  }

  /// Get cached messages for a room
  Future<List<ChatMessageModel>> getCachedMessages({
    required String roomId,
  }) async {
    final messagesJson = _prefs.getString('$_messagesPrefix$roomId');
    if (messagesJson == null) return [];

    try {
      final messagesList = jsonDecode(messagesJson) as List;
      return messagesList
          .cast<Map<String, dynamic>>()
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      // If parsing fails, clear cached data
      await clearMessages(roomId: roomId);
      return [];
    }
  }

  /// Add a single message to cache
  Future<void> cacheMessage({
    required String roomId,
    required ChatMessageModel message,
  }) async {
    final cachedMessages = await getCachedMessages(roomId: roomId);
    
    // Check if message already exists
    final existingIndex = cachedMessages.indexWhere((m) => m.id == message.id);
    
    if (existingIndex >= 0) {
      // Update existing message
      cachedMessages[existingIndex] = message;
    } else {
      // Add new message in correct chronological position
      cachedMessages.add(message);
      cachedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    await cacheMessages(roomId: roomId, messages: cachedMessages);
  }

  /// Remove a message from cache
  Future<void> removeMessage({
    required String roomId,
    required String messageId,
  }) async {
    final cachedMessages = await getCachedMessages(roomId: roomId);
    cachedMessages.removeWhere((m) => m.id == messageId);
    await cacheMessages(roomId: roomId, messages: cachedMessages);
  }

  /// Cache user's rooms
  Future<void> cacheRooms(List<RoomModel> rooms) async {
    final roomsList = rooms.map((r) => r.toJson()).toList();
    await _prefs.setString(
      '${_roomsPrefix}user_rooms',
      jsonEncode(roomsList),
    );
  }

  /// Get cached user's rooms
  Future<List<RoomModel>> getCachedRooms() async {
    final roomsJson = _prefs.getString('${_roomsPrefix}user_rooms');
    if (roomsJson == null) return [];

    try {
      final roomsList = jsonDecode(roomsJson) as List;
      return roomsList
          .cast<Map<String, dynamic>>()
          .map((json) => RoomModel.fromJson(json))
          .toList();
    } catch (e) {
      // If parsing fails, clear cached data
      await clearRooms();
      return [];
    }
  }

  /// Cache a single room
  Future<void> cacheRoom(RoomModel room) async {
    final cachedRooms = await getCachedRooms();
    final existingIndex = cachedRooms.indexWhere((r) => r.id == room.id);
    
    if (existingIndex >= 0) {
      cachedRooms[existingIndex] = room;
    } else {
      cachedRooms.add(room);
    }
    
    await cacheRooms(cachedRooms);
  }

  /// Remove a room from cache
  Future<void> removeRoom(String roomId) async {
    final cachedRooms = await getCachedRooms();
    cachedRooms.removeWhere((r) => r.id == roomId);
    await cacheRooms(cachedRooms);
    
    // Also clear related messages and threads
    await clearMessages(roomId: roomId);
    await clearThreads(roomId: roomId);
  }

  /// Cache threads for a room
  Future<void> cacheThreads({
    required String roomId,
    required List<MessageThreadModel> threads,
  }) async {
    final threadsList = threads.map((t) => t.toJson()).toList();
    await _prefs.setString(
      '$_threadsPrefix$roomId',
      jsonEncode(threadsList),
    );
  }

  /// Get cached threads for a room
  Future<List<MessageThreadModel>> getCachedThreads({
    required String roomId,
  }) async {
    final threadsJson = _prefs.getString('$_threadsPrefix$roomId');
    if (threadsJson == null) return [];

    try {
      final threadsList = jsonDecode(threadsJson) as List;
      return threadsList
          .cast<Map<String, dynamic>>()
          .map((json) => MessageThreadModel.fromJson(json))
          .toList();
    } catch (e) {
      // If parsing fails, clear cached data
      await clearThreads(roomId: roomId);
      return [];
    }
  }

  /// Cache a single thread
  Future<void> cacheThread({
    required String roomId,
    required MessageThreadModel thread,
  }) async {
    final cachedThreads = await getCachedThreads(roomId: roomId);
    final existingIndex = cachedThreads.indexWhere((t) => t.id == thread.id);
    
    if (existingIndex >= 0) {
      cachedThreads[existingIndex] = thread;
    } else {
      cachedThreads.add(thread);
    }
    
    await cacheThreads(roomId: roomId, threads: cachedThreads);
  }

  /// Get last sync timestamp for a room
  Future<DateTime?> getLastSync(String roomId) async {
    final timestamp = _prefs.getInt('$_lastSyncPrefix$roomId');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update last sync timestamp for a room
  Future<void> _updateLastSync(String roomId) async {
    await _prefs.setInt(
      '$_lastSyncPrefix$roomId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Clear cached messages for a room
  Future<void> clearMessages({required String roomId}) async {
    await _prefs.remove('$_messagesPrefix$roomId');
    await _prefs.remove('$_lastSyncPrefix$roomId');
  }

  /// Clear cached rooms
  Future<void> clearRooms() async {
    await _prefs.remove('${_roomsPrefix}user_rooms');
  }

  /// Clear cached threads for a room
  Future<void> clearThreads({required String roomId}) async {
    await _prefs.remove('$_threadsPrefix$roomId');
  }

  /// Clear all chat cache
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys().where((key) => 
      key.startsWith(_messagesPrefix) ||
      key.startsWith(_roomsPrefix) ||
      key.startsWith(_threadsPrefix) ||
      key.startsWith(_lastSyncPrefix)
    ).toList();

    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Check if room has cached messages
  Future<bool> hasMessages(String roomId) async {
    return _prefs.containsKey('$_messagesPrefix$roomId');
  }

  /// Check if user has cached rooms
  Future<bool> hasRooms() async {
    return _prefs.containsKey('${_roomsPrefix}user_rooms');
  }

  /// Check if room has cached threads
  Future<bool> hasThreads(String roomId) async {
    return _prefs.containsKey('$_threadsPrefix$roomId');
  }
}