import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// Widget that displays meeting participants in a grid layout
class ParticipantGrid extends StatefulWidget {
  const ParticipantGrid({
    required this.room,
    super.key,
  });

  final Room room;

  @override
  State<ParticipantGrid> createState() => _ParticipantGridState();
}

class _ParticipantGridState extends State<ParticipantGrid> {
  List<ParticipantTrack> _participantTracks = [];
  
  @override
  void initState() {
    super.initState();
    _setupParticipantListeners();
    _updateParticipantTracks();
  }
  
  @override
  void dispose() {
    _removeParticipantListeners();
    super.dispose();
  }
  
  void _setupParticipantListeners() {
    // Listen to room events for participant changes
    widget.room.addListener(_onRoomUpdated);
    
    // Listen to each participant's track changes
    for (final participant in widget.room.remoteParticipants.values) {
      participant.addListener(_onParticipantUpdated);
    }
    
    // Also listen to local participant
    widget.room.localParticipant?.addListener(_onParticipantUpdated);
  }
  
  void _removeParticipantListeners() {
    widget.room.removeListener(_onRoomUpdated);
    
    for (final participant in widget.room.remoteParticipants.values) {
      participant.removeListener(_onParticipantUpdated);
    }
    
    widget.room.localParticipant?.removeListener(_onParticipantUpdated);
  }
  
  void _onRoomUpdated() {
    _updateParticipantTracks();
  }
  
  void _onParticipantUpdated() {
    _updateParticipantTracks();
  }
  
  void _updateParticipantTracks() {
    if (!mounted) return;
    
    setState(() {
      _participantTracks = _getParticipantTracks();
    });
  }
  
  List<ParticipantTrack> _getParticipantTracks() {
    final tracks = <ParticipantTrack>[];
    
    // Add local participant track if available
    final localParticipant = widget.room.localParticipant;
    if (localParticipant != null) {
      final videoPublication = localParticipant.videoTrackPublications
          .where((pub) => pub.subscribed && pub.track != null)
          .firstOrNull;
      final videoTrack = videoPublication?.track as VideoTrack?;
      
      if (videoTrack != null) {
        tracks.add(ParticipantTrack(
          participant: localParticipant,
          videoTrack: videoTrack,
          isLocal: true,
        ));
      }
    }
    
    // Add remote participants' tracks
    for (final participant in widget.room.remoteParticipants.values) {
      final videoPublication = participant.videoTrackPublications
          .where((pub) => pub.subscribed && pub.track != null)
          .firstOrNull;
      final videoTrack = videoPublication?.track as VideoTrack?;
      
      if (videoTrack != null) {
        tracks.add(ParticipantTrack(
          participant: participant,
          videoTrack: videoTrack,
          isLocal: false,
        ));
      }
    }
    
    return tracks;
  }
  
  int _getGridColumns(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    if (participantCount <= 9) return 3;
    return 4;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_participantTracks.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'No video streams',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
              Text(
                'Waiting for participants to join...',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final columns = _getGridColumns(_participantTracks.length);
    
    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        itemCount: _participantTracks.length,
        itemBuilder: (context, index) {
          final participantTrack = _participantTracks[index];
          return ParticipantTile(
            participantTrack: participantTrack,
            onTap: () => _onParticipantTileTap(participantTrack),
          );
        },
      ),
    );
  }
  
  void _onParticipantTileTap(ParticipantTrack participantTrack) {
    // Handle participant tile tap (e.g., focus view, show controls)
    if (!participantTrack.isLocal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing ${participantTrack.participant.name ?? 'Unknown'}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

/// Represents a participant and their video track
class ParticipantTrack {
  const ParticipantTrack({
    required this.participant,
    required this.videoTrack,
    required this.isLocal,
  });
  
  final Participant participant;
  final VideoTrack videoTrack;
  final bool isLocal;
}

/// Individual participant tile widget
class ParticipantTile extends StatefulWidget {
  const ParticipantTile({
    required this.participantTrack,
    this.onTap,
    super.key,
  });
  
  final ParticipantTrack participantTrack;
  final VoidCallback? onTap;
  
  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    widget.participantTrack.participant.addListener(_onParticipantUpdated);
  }
  
  @override
  void dispose() {
    widget.participantTrack.participant.removeListener(_onParticipantUpdated);
    super.dispose();
  }
  
  void _onParticipantUpdated() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final participant = widget.participantTrack.participant;
    final videoTrack = widget.participantTrack.videoTrack;
    final isLocal = widget.participantTrack.isLocal;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered 
                  ? const Color(0xFF25D366)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Video renderer
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: VideoTrackRenderer(
                  videoTrack,
                  fit: VideoFit.cover,
                ),
              ),
              
              // Participant info overlay
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Microphone status
                      Icon(
                        participant.isMicrophoneEnabled()
                            ? Icons.mic
                            : Icons.mic_off,
                        size: 16,
                        color: participant.isMicrophoneEnabled()
                            ? Colors.white
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      
                      // Participant name
                      Expanded(
                        child: Text(
                          isLocal 
                              ? '${participant.name ?? 'You'} (You)'
                              : participant.name ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Connection quality indicator
                      if (participant.connectionQuality != ConnectionQuality.unknown)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: _buildConnectionQualityIndicator(
                            participant.connectionQuality,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Screen share indicator
              if (_isScreenSharing(participant))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.screen_share,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Local video indicator
              if (isLocal)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectionQualityIndicator(ConnectionQuality quality) {
    Color color;
    IconData icon;
    
    switch (quality) {
      case ConnectionQuality.excellent:
        color = Colors.green;
        icon = Icons.signal_cellular_4_bar;
        break;
      case ConnectionQuality.good:
        color = Colors.yellow;
        icon = Icons.signal_cellular_alt;
        break;
      case ConnectionQuality.poor:
        color = Colors.orange;
        icon = Icons.signal_cellular_connected_no_internet_4_bar;
        break;
      default:
        color = Colors.red;
        icon = Icons.signal_cellular_0_bar;
    }
    
    return Icon(
      icon,
      size: 12,
      color: color,
    );
  }
  
  bool _isScreenSharing(Participant participant) {
    return participant.videoTrackPublications
        .any((pub) => pub.source == TrackSource.screenShareVideo);
  }
}