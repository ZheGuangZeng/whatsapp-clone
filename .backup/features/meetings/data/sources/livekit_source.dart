import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:livekit_client/livekit_client.dart' as livekit;

import '../../../core/errors/exceptions.dart';
import '../../domain/entities/meeting_participant.dart';
import '../../domain/entities/meeting_state.dart';

/// Data source for LiveKit WebRTC operations
class LivekitSource {
  LivekitSource({
    this.livekitUrl = 'wss://whatsapp-clone.livekit.cloud',
  }) {
    _room = livekit.Room();
    _setupRoomListeners();
  }

  /// LiveKit server URL
  final String livekitUrl;

  /// LiveKit room instance
  late final livekit.Room _room;

  /// Current meeting state stream controller
  final _meetingStateController = StreamController<MeetingState>.broadcast();

  /// Participants stream controller
  final _participantsController = StreamController<List<MeetingParticipant>>.broadcast();

  /// Connection state stream controller
  final _connectionStateController = StreamController<MeetingConnectionState>.broadcast();

  /// Current meeting state
  MeetingState _currentState = const MeetingState();

  /// Get current room instance
  livekit.Room get room => _room;

  /// Get current meeting state
  MeetingState get currentState => _currentState;

  /// Stream of meeting state changes
  Stream<MeetingState> get meetingStateStream => _meetingStateController.stream;

  /// Stream of participant changes
  Stream<List<MeetingParticipant>> get participantsStream => _participantsController.stream;

  /// Stream of connection state changes
  Stream<MeetingConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// Connect to a meeting room
  Future<void> connect({
    required String roomName,
    required String accessToken,
    bool enableAudio = true,
    bool enableVideo = true,
  }) async {
    try {
      _updateState(_currentState.copyWith(
        connectionState: MeetingConnectionState.connecting,
      ));

      // Set up local participant options
      final roomOptions = livekit.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: const livekit.CameraCaptureOptions(
          maxFrameRate: 30.0,
          resolution: livekit.VideoCaptureResolution.h720_169,
        ),
      );

      // Connect to the room
      await _room.connect(
        livekitUrl,
        accessToken,
        roomOptions: roomOptions,
      );

      // Enable hardware codecs for better performance
      await livekit.Hardware.instance.enableCodec(livekit.Codec.h264);

      // Set up local media
      if (enableAudio) {
        await _room.localParticipant?.setMicrophoneEnabled(true);
      }

      if (enableVideo) {
        await _room.localParticipant?.setCameraEnabled(true);
      }

      _updateState(_currentState.copyWith(
        connectionState: MeetingConnectionState.connected,
        livekitRoom: _room,
        isAudioEnabled: enableAudio,
        isVideoEnabled: enableVideo,
        isMicrophoneMuted: !enableAudio,
        isCameraOff: !enableVideo,
      ));

    } catch (error) {
      _updateState(_currentState.copyWith(
        connectionState: MeetingConnectionState.failed,
        error: 'Failed to connect to meeting: $error',
      ));
      throw ServerException('Failed to connect to LiveKit room: $error');
    }
  }

  /// Disconnect from the meeting room
  Future<void> disconnect() async {
    try {
      await _room.disconnect();
      
      _updateState(_currentState.copyWith(
        connectionState: MeetingConnectionState.disconnected,
        livekitRoom: null,
        localParticipant: null,
        remoteParticipants: [],
      ));
    } catch (error) {
      throw ServerException('Failed to disconnect from LiveKit room: $error');
    }
  }

  /// Toggle microphone
  Future<void> toggleMicrophone() async {
    try {
      final isEnabled = _room.localParticipant?.isMicrophoneEnabled() ?? false;
      await _room.localParticipant?.setMicrophoneEnabled(!isEnabled);
      
      _updateState(_currentState.copyWith(
        isMicrophoneMuted: isEnabled, // If was enabled, now muted
      ));
    } catch (error) {
      throw ServerException('Failed to toggle microphone: $error');
    }
  }

  /// Toggle camera
  Future<void> toggleCamera() async {
    try {
      final isEnabled = _room.localParticipant?.isCameraEnabled() ?? false;
      await _room.localParticipant?.setCameraEnabled(!isEnabled);
      
      _updateState(_currentState.copyWith(
        isCameraOff: isEnabled, // If was enabled, now off
      ));
    } catch (error) {
      throw ServerException('Failed to toggle camera: $error');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      final localParticipant = _room.localParticipant;
      if (localParticipant == null) return;

      final videoTrack = localParticipant.videoTracks.firstOrNull?.track;
      if (videoTrack is livekit.LocalVideoTrack) {
        await videoTrack.setCameraPosition(
          videoTrack.currentOptions.cameraPosition == livekit.CameraPosition.front
              ? livekit.CameraPosition.back
              : livekit.CameraPosition.front,
        );
      }
    } catch (error) {
      throw ServerException('Failed to switch camera: $error');
    }
  }

  /// Start screen sharing
  Future<void> startScreenShare() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        // Mobile screen sharing implementation
        await _room.localParticipant?.setScreenShareEnabled(true);
      } else {
        // Desktop screen sharing implementation
        await _room.localParticipant?.setScreenShareEnabled(true);
      }

      _updateState(_currentState.copyWith(
        isScreenSharing: true,
      ));
    } catch (error) {
      throw ServerException('Failed to start screen sharing: $error');
    }
  }

  /// Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      await _room.localParticipant?.setScreenShareEnabled(false);
      
      _updateState(_currentState.copyWith(
        isScreenSharing: false,
      ));
    } catch (error) {
      throw ServerException('Failed to stop screen sharing: $error');
    }
  }

  /// Send data message to participants
  Future<void> sendData({
    required String data,
    List<String>? destinationSids,
    String? topic,
  }) async {
    try {
      await _room.localParticipant?.publishData(
        utf8.encode(data),
        destinationIdentities: destinationSids,
        topic: topic,
      );
    } catch (error) {
      throw ServerException('Failed to send data: $error');
    }
  }

  /// Get room statistics
  Map<String, dynamic> getRoomStats() {
    final localParticipant = _room.localParticipant;
    final remoteParticipants = _room.remoteParticipants;

    return {
      'roomName': _room.name,
      'isConnected': _room.connectionState == livekit.ConnectionState.connected,
      'participantCount': 1 + remoteParticipants.length,
      'localParticipant': {
        'identity': localParticipant?.identity,
        'audioEnabled': localParticipant?.isMicrophoneEnabled(),
        'videoEnabled': localParticipant?.isCameraEnabled(),
        'screenShareEnabled': localParticipant?.isScreenShareEnabled(),
      },
      'remoteParticipants': remoteParticipants.map((p) => {
        'identity': p.identity,
        'audioTracks': p.audioTracks.length,
        'videoTracks': p.videoTracks.length,
      }).toList(),
    };
  }

  /// Set up room event listeners
  void _setupRoomListeners() {
    _room
      ..addListener(_onRoomUpdate)
      ..on<livekit.RoomConnectedEvent>((event) => _onRoomConnected())
      ..on<livekit.RoomDisconnectedEvent>((event) => _onRoomDisconnected(event))
      ..on<livekit.ParticipantConnectedEvent>((event) => _onParticipantConnected(event.participant))
      ..on<livekit.ParticipantDisconnectedEvent>((event) => _onParticipantDisconnected(event.participant))
      ..on<livekit.TrackMutedEvent>((event) => _onTrackMuted(event))
      ..on<livekit.TrackUnmutedEvent>((event) => _onTrackUnmuted(event))
      ..on<livekit.DataReceivedEvent>((event) => _onDataReceived(event))
      ..on<livekit.ConnectionQualityChangedEvent>((event) => _onConnectionQualityChanged(event));
  }

  /// Handle room updates
  void _onRoomUpdate() {
    _updateParticipants();
  }

  /// Handle room connected event
  void _onRoomConnected() {
    _updateState(_currentState.copyWith(
      connectionState: MeetingConnectionState.connected,
      livekitRoom: _room,
    ));
    _updateParticipants();
  }

  /// Handle room disconnected event
  void _onRoomDisconnected(livekit.RoomDisconnectedEvent event) {
    final connectionState = event.reason == livekit.DisconnectReason.unknown
        ? MeetingConnectionState.failed
        : MeetingConnectionState.disconnected;

    _updateState(_currentState.copyWith(
      connectionState: connectionState,
      livekitRoom: null,
      localParticipant: null,
      remoteParticipants: [],
    ));
  }

  /// Handle participant connected event
  void _onParticipantConnected(livekit.RemoteParticipant participant) {
    _updateParticipants();
  }

  /// Handle participant disconnected event
  void _onParticipantDisconnected(livekit.RemoteParticipant participant) {
    _updateParticipants();
  }

  /// Handle track muted event
  void _onTrackMuted(livekit.TrackMutedEvent event) {
    _updateParticipants();
  }

  /// Handle track unmuted event
  void _onTrackUnmuted(livekit.TrackUnmutedEvent event) {
    _updateParticipants();
  }

  /// Handle data received event
  void _onDataReceived(livekit.DataReceivedEvent event) {
    // Handle custom data messages
    // This could be used for custom signaling, reactions, etc.
  }

  /// Handle connection quality changed event
  void _onConnectionQualityChanged(livekit.ConnectionQualityChangedEvent event) {
    _updateState(_currentState.copyWith(
      networkQuality: event.quality,
    ));
  }

  /// Update meeting state
  void _updateState(MeetingState newState) {
    _currentState = newState;
    _meetingStateController.add(newState);
    _connectionStateController.add(newState.connectionState);
  }

  /// Update participants list
  void _updateParticipants() {
    final participants = <MeetingParticipant>[];
    
    // Add local participant
    final localParticipant = _room.localParticipant;
    if (localParticipant != null) {
      participants.add(_convertToMeetingParticipant(localParticipant, isLocal: true));
    }

    // Add remote participants
    for (final remoteParticipant in _room.remoteParticipants.values) {
      participants.add(_convertToMeetingParticipant(remoteParticipant));
    }

    _updateState(_currentState.copyWith(
      localParticipant: participants.where((p) => p.livekitParticipantId == localParticipant?.identity).firstOrNull,
      remoteParticipants: participants.where((p) => p.livekitParticipantId != localParticipant?.identity).toList(),
    ));

    _participantsController.add(participants);
  }

  /// Convert LiveKit participant to domain participant
  MeetingParticipant _convertToMeetingParticipant(
    livekit.Participant participant, {
    bool isLocal = false,
  }) {
    return MeetingParticipant(
      id: participant.identity, // Temporary ID, should be mapped properly
      meetingId: _room.name ?? '',
      userId: participant.identity,
      livekitParticipantId: participant.identity,
      role: isLocal ? ParticipantRole.host : ParticipantRole.participant, // Default role
      joinedAt: DateTime.now(), // Should be tracked properly
      connectionQuality: _mapConnectionQuality(participant.connectionQuality),
      isAudioEnabled: participant.audioTracks.isNotEmpty,
      isVideoEnabled: participant.videoTracks.isNotEmpty,
      isScreenSharing: participant.screenShareTracks.isNotEmpty,
      displayName: participant.name ?? participant.identity,
      metadata: participant.metadata != null ? {'livekit_metadata': participant.metadata} : {},
    );
  }

  /// Map LiveKit connection quality to domain enum
  ConnectionQuality _mapConnectionQuality(livekit.ConnectionQuality quality) {
    switch (quality) {
      case livekit.ConnectionQuality.excellent:
        return ConnectionQuality.excellent;
      case livekit.ConnectionQuality.good:
        return ConnectionQuality.good;
      case livekit.ConnectionQuality.poor:
        return ConnectionQuality.poor;
      case livekit.ConnectionQuality.lost:
        return ConnectionQuality.lost;
    }
  }

  /// Dispose resources
  void dispose() {
    _room.dispose();
    _meetingStateController.close();
    _participantsController.close();
    _connectionStateController.close();
  }
}