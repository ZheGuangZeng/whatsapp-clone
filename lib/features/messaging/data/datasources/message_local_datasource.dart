import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

/// Local datasource for offline message operations
class MessageLocalDataSource {
  const MessageLocalDataSource(this._prefs);
  
  final SharedPreferences _prefs;
  
  static const String _queuedMessagesKey = 'queued_messages';
  static const String _cachedMessagesPrefix = 'cached_messages_';

  /// Queue a message for offline sync
  Future<void> queueMessage(MessageModel message) async {
    try {
      final queuedMessages = await getQueuedMessages();
      queuedMessages.add(message);
      
      final jsonList = queuedMessages.map((m) => m.toJson()).toList();
      await _prefs.setString(_queuedMessagesKey, jsonEncode(jsonList));
    } catch (e) {
      throw Exception('Failed to queue message: $e');
    }
  }

  /// Get all queued messages for sync
  Future<List<MessageModel>> getQueuedMessages() async {
    try {
      final jsonString = _prefs.getString(_queuedMessagesKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map<MessageModel>((dynamic json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get queued messages: $e');
    }
  }

  /// Remove message from queue after successful sync
  Future<void> removeFromQueue(String messageId) async {
    try {
      final queuedMessages = await getQueuedMessages();
      queuedMessages.removeWhere((m) => m.id == messageId);
      
      final jsonList = queuedMessages.map((m) => m.toJson()).toList();
      await _prefs.setString(_queuedMessagesKey, jsonEncode(jsonList));
    } catch (e) {
      throw Exception('Failed to remove message from queue: $e');
    }
  }

  /// Clear all queued messages
  Future<void> clearQueue() async {
    try {
      await _prefs.remove(_queuedMessagesKey);
    } catch (e) {
      throw Exception('Failed to clear message queue: $e');
    }
  }

  /// Cache messages for a room (for offline viewing)
  Future<void> cacheRoomMessages(String roomId, List<MessageModel> messages) async {
    try {
      final key = _cachedMessagesPrefix + roomId;
      final jsonList = messages.map((m) => m.toJson()).toList();
      await _prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      throw Exception('Failed to cache room messages: $e');
    }
  }

  /// Get cached messages for a room
  Future<List<MessageModel>> getCachedRoomMessages(String roomId) async {
    try {
      final key = _cachedMessagesPrefix + roomId;
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map<MessageModel>((dynamic json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get cached room messages: $e');
    }
  }

  /// Clear cached messages for a room
  Future<void> clearRoomCache(String roomId) async {
    try {
      final key = _cachedMessagesPrefix + roomId;
      await _prefs.remove(key);
    } catch (e) {
      throw Exception('Failed to clear room cache: $e');
    }
  }

  /// Clear all cached messages
  Future<void> clearAllCache() async {
    try {
      final keys = _prefs.getKeys()
          .where((key) => key.startsWith(_cachedMessagesPrefix))
          .toList();
      
      for (final key in keys) {
        await _prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Failed to clear all message cache: $e');
    }
  }

  /// Update cached message (for optimistic updates)
  Future<void> updateCachedMessage(String roomId, MessageModel message) async {
    try {
      final cachedMessages = await getCachedRoomMessages(roomId);
      final index = cachedMessages.indexWhere((m) => m.id == message.id);
      
      if (index >= 0) {
        cachedMessages[index] = message;
        await cacheRoomMessages(roomId, cachedMessages);
      }
    } catch (e) {
      throw Exception('Failed to update cached message: $e');
    }
  }

  /// Add message to cache (for new messages)
  Future<void> addToCachedMessages(String roomId, MessageModel message) async {
    try {
      final cachedMessages = await getCachedRoomMessages(roomId);
      
      // Avoid duplicates
      if (!cachedMessages.any((m) => m.id == message.id)) {
        cachedMessages.insert(0, message); // Add to beginning for latest first
        
        // Keep only latest 100 messages to manage storage
        if (cachedMessages.length > 100) {
          cachedMessages.removeRange(100, cachedMessages.length);
        }
        
        await cacheRoomMessages(roomId, cachedMessages);
      }
    } catch (e) {
      throw Exception('Failed to add message to cache: $e');
    }
  }
}