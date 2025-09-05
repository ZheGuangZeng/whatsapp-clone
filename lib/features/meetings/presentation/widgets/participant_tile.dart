import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;

import '../../domain/entities/meeting_participant.dart';

/// Widget that displays a single participant in the meeting grid
class ParticipantTile extends StatefulWidget {
  const ParticipantTile({
    super.key,
    required this.participant,
    this.livekitParticipant,
    this.isLocal = false,
    this.isDominantSpeaker = false,
    this.onTap,
    this.showControls = true,
    this.borderRadius = 8.0,
  });

  final MeetingParticipant participant;
  final livekit.Participant? livekitParticipant;
  final bool isLocal;
  final bool isDominantSpeaker;
  final VoidCallback? onTap;
  final bool showControls;
  final double borderRadius;

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  livekit.VideoTrack? _videoTrack;
  livekit.AudioTrack? _audioTrack;

  @override
  void initState() {
    super.initState();
    _setupTracks();
  }

  @override
  void didUpdateWidget(ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.livekitParticipant != widget.livekitParticipant) {
      _setupTracks();
    }
  }

  void _setupTracks() {
    final participant = widget.livekitParticipant;
    if (participant == null) return;

    // Get video track
    final videoTrackPub = participant.videoTrackPublications.firstOrNull;
    _videoTrack = videoTrackPub?.track as livekit.VideoTrack?;

    // Get audio track
    final audioTrackPub = participant.audioTrackPublications.firstOrNull;
    _audioTrack = audioTrackPub?.track as livekit.AudioTrack?;

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.isDominantSpeaker
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 3,
                )
              : Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
          boxShadow: widget.isDominantSpeaker
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              // Video or avatar background
              Positioned.fill(
                child: _buildVideoOrAvatar(context),
              ),
              
              // Overlay with participant info
              if (widget.showControls) ...[
                // Top bar with name and status
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: _buildTopBar(context),
                ),
                
                // Bottom bar with controls
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: _buildBottomBar(context),
                ),
              ],
              
              // Connection quality indicator
              Positioned(
                top: 8,
                right: 8,
                child: _buildConnectionQuality(),
              ),
              
              // Loading indicator for connecting participants
              if (widget.livekitParticipant == null)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOrAvatar(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_videoTrack != null && widget.participant.isVideoEnabled) {
      return livekit.VideoTrackRenderer(
        _videoTrack!,
        fit: livekit.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirrorMode: widget.isLocal ? livekit.VideoViewMirrorMode.mirrorLocalViewOnly : livekit.VideoViewMirrorMode.off,
      );
    }

    // Show avatar when no video
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: widget.participant.avatarUrl != null
                  ? NetworkImage(widget.participant.avatarUrl!)
                  : null,
              child: widget.participant.avatarUrl == null
                  ? Text(
                      _getInitials(widget.participant.displayNameOrFallback),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              widget.participant.displayNameOrFallback,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.participant.displayNameOrFallback,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.isLocal) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio indicator
          Icon(
            widget.participant.isAudioEnabled
                ? Icons.mic
                : Icons.mic_off,
            size: 16,
            color: widget.participant.isAudioEnabled
                ? Colors.white
                : Colors.red,
          ),
          const SizedBox(width: 8),
          
          // Video indicator
          Icon(
            widget.participant.isVideoEnabled
                ? Icons.videocam
                : Icons.videocam_off,
            size: 16,
            color: widget.participant.isVideoEnabled
                ? Colors.white
                : Colors.red,
          ),
          
          // Screen sharing indicator
          if (widget.participant.isScreenSharing) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.screen_share,
              size: 16,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionQuality() {
    IconData icon;
    Color color;
    
    switch (widget.participant.connectionQuality) {
      case ConnectionQuality.excellent:
        icon = Icons.signal_cellular_4_bar;
        color = Colors.green;
        break;
      case ConnectionQuality.good:
        icon = Icons.signal_cellular_4_bar;
        color = Colors.yellow;
        break;
      case ConnectionQuality.poor:
        icon = Icons.signal_cellular_2_bar;
        color = Colors.orange;
        break;
      case ConnectionQuality.lost:
        icon = Icons.signal_cellular_0_bar;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }
}

/// Extension to safely get first element or null
extension _IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}