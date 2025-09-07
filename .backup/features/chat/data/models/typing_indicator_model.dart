import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/typing_indicator.dart';

part 'typing_indicator_model.g.dart';

/// Data model for TypingIndicator entity with JSON serialization
@JsonSerializable()
class TypingIndicatorModel extends TypingIndicator {
  const TypingIndicatorModel({
    required super.roomId,
    required super.userId,
    required super.displayName,
    required super.isTyping,
    required super.updatedAt,
  });

  /// Creates TypingIndicatorModel from JSON
  factory TypingIndicatorModel.fromJson(Map<String, dynamic> json) =>
      _$TypingIndicatorModelFromJson(json);

  /// Creates TypingIndicatorModel from domain entity
  factory TypingIndicatorModel.fromEntity(TypingIndicator indicator) =>
      TypingIndicatorModel(
        roomId: indicator.roomId,
        userId: indicator.userId,
        displayName: indicator.displayName,
        isTyping: indicator.isTyping,
        updatedAt: indicator.updatedAt,
      );

  /// Creates TypingIndicatorModel from Supabase response
  factory TypingIndicatorModel.fromSupabase(Map<String, dynamic> data) =>
      TypingIndicatorModel(
        roomId: data['room_id'] as String,
        userId: data['user_id'] as String,
        displayName: data['display_name'] as String? ?? 'Unknown User',
        isTyping: data['is_typing'] as bool,
        updatedAt: DateTime.parse(data['updated_at'] as String),
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$TypingIndicatorModelToJson(this);

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() => {
        'room_id': roomId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Converts to domain entity
  TypingIndicator toEntity() => TypingIndicator(
        roomId: roomId,
        userId: userId,
        displayName: displayName,
        isTyping: isTyping,
        updatedAt: updatedAt,
      );
}