import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;

import '../../domain/entities/meeting_participant.dart';
import 'participant_tile.dart';

/// Widget that displays meeting participants in a responsive grid layout
class ParticipantGrid extends StatefulWidget {
  const ParticipantGrid({
    super.key,
    required this.participants,
    required this.room,
    this.localParticipant,
    this.dominantSpeaker,
    this.onParticipantTap,
    this.maxTilesPerRow = 3,
    this.aspectRatio = 16 / 9,
  });

  final List<MeetingParticipant> participants;
  final livekit.Room room;
  final MeetingParticipant? localParticipant;
  final MeetingParticipant? dominantSpeaker;
  final ValueChanged<MeetingParticipant>? onParticipantTap;
  final int maxTilesPerRow;
  final double aspectRatio;

  @override
  State<ParticipantGrid> createState() => _ParticipantGridState();
}

class _ParticipantGridState extends State<ParticipantGrid> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No participants in this meeting',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final participantCount = widget.participants.length;
        final gridDimensions = _calculateGridDimensions(
          participantCount,
          constraints,
        );

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridDimensions.crossAxisCount,
              childAspectRatio: widget.aspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: participantCount,
            itemBuilder: (context, index) {
              final participant = widget.participants[index];
              final isLocalParticipant = participant.userId == widget.localParticipant?.userId;
              final isDominantSpeaker = participant.userId == widget.dominantSpeaker?.userId;
              
              // Find corresponding LiveKit participant
              livekit.Participant? livekitParticipant;
              if (isLocalParticipant) {
                livekitParticipant = widget.room.localParticipant;
              } else {
                livekitParticipant = widget.room.remoteParticipants.values
                    .where((p) => p.identity == participant.userId)
                    .firstOrNull;
              }

              return ParticipantTile(
                key: ValueKey('participant_${participant.userId}'),
                participant: participant,
                livekitParticipant: livekitParticipant,
                isLocal: isLocalParticipant,
                isDominantSpeaker: isDominantSpeaker,
                onTap: widget.onParticipantTap != null
                    ? () => widget.onParticipantTap!(participant)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  /// Calculate optimal grid dimensions based on participant count and constraints
  GridDimensions _calculateGridDimensions(
    int participantCount,
    BoxConstraints constraints,
  ) {
    if (participantCount == 1) {
      return const GridDimensions(crossAxisCount: 1, mainAxisCount: 1);
    }

    if (participantCount == 2) {
      // For 2 participants, use side-by-side on landscape, stacked on portrait
      final isLandscape = constraints.maxWidth > constraints.maxHeight;
      return GridDimensions(
        crossAxisCount: isLandscape ? 2 : 1,
        mainAxisCount: isLandscape ? 1 : 2,
      );
    }

    if (participantCount <= 4) {
      return const GridDimensions(crossAxisCount: 2, mainAxisCount: 2);
    }

    if (participantCount <= 6) {
      return const GridDimensions(crossAxisCount: 3, mainAxisCount: 2);
    }

    if (participantCount <= 9) {
      return const GridDimensions(crossAxisCount: 3, mainAxisCount: 3);
    }

    if (participantCount <= 16) {
      return const GridDimensions(crossAxisCount: 4, mainAxisCount: 4);
    }

    // For larger meetings, optimize based on screen size
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    
    // Calculate optimal tile size (minimum 120px width for readability)
    final minTileWidth = 120.0;
    final maxCrossAxisCount = (screenWidth / minTileWidth).floor().clamp(2, 6);
    
    final crossAxisCount = maxCrossAxisCount.clamp(2, widget.maxTilesPerRow);
    final mainAxisCount = (participantCount / crossAxisCount).ceil();
    
    return GridDimensions(
      crossAxisCount: crossAxisCount,
      mainAxisCount: mainAxisCount,
    );
  }
}

/// Data class for grid dimensions
class GridDimensions {
  const GridDimensions({
    required this.crossAxisCount,
    required this.mainAxisCount,
  });

  final int crossAxisCount;
  final int mainAxisCount;
}

/// Extension to safely get first element or null
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}