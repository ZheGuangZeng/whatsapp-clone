import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';

/// Service for generating LiveKit access tokens
/// NOTE: In production, this should be done server-side for security
class LiveKitTokenService {
  static const String _logTag = 'LiveKitTokenService';
  
  final String _apiKey;
  final String _apiSecret;
  
  LiveKitTokenService({
    required String apiKey,
    required String apiSecret,
  }) : _apiKey = apiKey,
       _apiSecret = apiSecret;
  
  /// Generates an access token for LiveKit room access
  Future<String> generateAccessToken({
    required String roomName,
    required String identity,
    String? name,
    Map<String, dynamic>? metadata,
    Duration? ttl,
    List<String>? grants,
  }) async {
    try {
      developer.log('Generating access token for $identity in room $roomName', name: _logTag);
      
      final now = DateTime.now();
      final expiry = now.add(ttl ?? const Duration(hours: 6));
      
      // Create JWT header
      final header = {
        'alg': 'HS256',
        'typ': 'JWT',
      };
      
      // Create JWT payload with LiveKit video grants
      final payload = {
        'iss': _apiKey,
        'sub': identity,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        'jti': identity,
        'video': {
          'room': roomName,
          'roomJoin': true,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
          'canUpdateOwnMetadata': true,
          'ingressAdmin': false,
          'hidden': false,
          'recorder': false,
        }
      };
      
      // Add optional fields
      if (name != null) {
        payload['name'] = name;
      }
      
      if (metadata != null) {
        payload['metadata'] = jsonEncode(metadata);
      }
      
      // Add custom grants if provided
      if (grants != null) {
        final videoGrants = payload['video'] as Map<String, dynamic>;
        for (final grant in grants) {
          switch (grant) {
            case 'admin':
              videoGrants['roomAdmin'] = true;
              break;
            case 'record':
              videoGrants['recorder'] = true;
              break;
            case 'screen_share':
              videoGrants['canPublishSources'] = ['camera', 'microphone', 'screen_share'];
              break;
          }
        }
      }
      
      // Encode JWT
      final token = _encodeJWT(header, payload, _apiSecret);
      
      developer.log('Successfully generated access token', name: _logTag);
      return token;
      
    } catch (error) {
      developer.log('Failed to generate access token: $error', name: _logTag, level: 1000);
      rethrow;
    }
  }
  
  /// Encodes a JWT token using HS256 algorithm
  String _encodeJWT(Map<String, dynamic> header, Map<String, dynamic> payload, String secret) {
    // Encode header and payload
    final encodedHeader = _base64UrlEncode(utf8.encode(jsonEncode(header)));
    final encodedPayload = _base64UrlEncode(utf8.encode(jsonEncode(payload)));
    
    // Create signature
    final message = '$encodedHeader.$encodedPayload';
    final secretBytes = utf8.encode(secret);
    final signature = Hmac(sha256, secretBytes).convert(utf8.encode(message));
    final encodedSignature = _base64UrlEncode(signature.bytes);
    
    return '$message.$encodedSignature';
  }
  
  /// Base64 URL-safe encoding (without padding)
  String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
  
  /// Validates a JWT token (for debugging purposes)
  bool validateToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      final payload = jsonDecode(utf8.decode(base64Url.decode(_padBase64(parts[1]))));
      
      // Check expiry
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expiryTime.isBefore(DateTime.now())) {
          return false;
        }
      }
      
      // Check issuer
      if (payload['iss'] != _apiKey) {
        return false;
      }
      
      return true;
    } catch (error) {
      developer.log('Token validation failed: $error', name: _logTag);
      return false;
    }
  }
  
  /// Adds padding to base64 string if needed
  String _padBase64(String base64) {
    final padding = 4 - (base64.length % 4);
    if (padding != 4) {
      return base64 + ('=' * padding);
    }
    return base64;
  }
}