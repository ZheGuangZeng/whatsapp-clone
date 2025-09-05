import 'package:flutter/material.dart';

import '../../domain/entities/meeting_participant.dart';
import '../../domain/entities/meeting_state.dart';

/// Widget that displays meeting control buttons
class MeetingControls extends StatelessWidget {
  const MeetingControls({
    super.key,
    required this.meetingState,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.onToggleScreenShare,
    required this.onSwitchCamera,
    required this.onLeaveMeeting,
    this.onEndMeeting,
    this.onShowParticipants,
    this.onShowChat,
    this.onShowSettings,
    this.showSecondaryControls = true,
    this.isCompact = false,
  });

  final MeetingState meetingState;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onSwitchCamera;
  final VoidCallback onLeaveMeeting;
  final VoidCallback? onEndMeeting;
  final VoidCallback? onShowParticipants;
  final VoidCallback? onShowChat;
  final VoidCallback? onShowSettings;
  final bool showSecondaryControls;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isCompact ? _buildCompactControls(context) : _buildFullControls(context),
    );
  }

  Widget _buildFullControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Secondary controls (left side)
        if (showSecondaryControls) ...[
          _buildSecondaryButton(
            context: context,
            icon: Icons.people,
            label: 'Participants',
            count: meetingState.activeParticipantsCount,
            onTap: onShowParticipants,
          ),
          _buildSecondaryButton(
            context: context,
            icon: Icons.chat,
            label: 'Chat',
            onTap: onShowChat,
          ),
        ],

        // Primary controls (center)
        _buildPrimaryButton(
          context: context,
          icon: meetingState.isAudioActive ? Icons.mic : Icons.mic_off,
          label: meetingState.isAudioActive ? 'Mute' : 'Unmute',
          isActive: meetingState.isAudioActive,
          onTap: onToggleAudio,
        ),

        _buildPrimaryButton(
          context: context,
          icon: meetingState.isVideoActive ? Icons.videocam : Icons.videocam_off,
          label: meetingState.isVideoActive ? 'Stop Video' : 'Start Video',
          isActive: meetingState.isVideoActive,
          onTap: onToggleVideo,
        ),

        if (meetingState.isVideoActive)
          _buildSecondaryButton(
            context: context,
            icon: Icons.flip_camera_ios,
            label: 'Switch',
            onTap: onSwitchCamera,
          ),

        _buildPrimaryButton(
          context: context,
          icon: meetingState.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
          label: meetingState.isScreenSharing ? 'Stop Share' : 'Share',
          isActive: meetingState.isScreenSharing,
          backgroundColor: meetingState.isScreenSharing ? Colors.green : null,
          onTap: onToggleScreenShare,
        ),

        // End/Leave controls (right side)
        if (meetingState.hasAdminPrivileges && onEndMeeting != null)
          _buildDangerButton(
            context: context,
            icon: Icons.call_end,
            label: 'End Meeting',
            onTap: onEndMeeting!,
          )
        else
          _buildDangerButton(
            context: context,
            icon: Icons.call_end,
            label: 'Leave',
            onTap: onLeaveMeeting,
          ),

        // Settings
        if (showSecondaryControls && onShowSettings != null)
          _buildSecondaryButton(
            context: context,
            icon: Icons.settings,
            label: 'Settings',
            onTap: onShowSettings,
          ),
      ],
    );
  }

  Widget _buildCompactControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactButton(
          context: context,
          icon: meetingState.isAudioActive ? Icons.mic : Icons.mic_off,
          isActive: meetingState.isAudioActive,
          onTap: onToggleAudio,
        ),
        _buildCompactButton(
          context: context,
          icon: meetingState.isVideoActive ? Icons.videocam : Icons.videocam_off,
          isActive: meetingState.isVideoActive,
          onTap: onToggleVideo,
        ),
        if (meetingState.isScreenSharing)
          _buildCompactButton(
            context: context,
            icon: Icons.stop_screen_share,
            isActive: true,
            backgroundColor: Colors.green,
            onTap: onToggleScreenShare,
          )
        else
          _buildCompactButton(
            context: context,
            icon: Icons.screen_share,
            isActive: false,
            onTap: onToggleScreenShare,
          ),
        _buildCompactButton(
          context: context,
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          onTap: meetingState.hasAdminPrivileges && onEndMeeting != null 
              ? onEndMeeting! 
              : onLeaveMeeting,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? 
        (isActive ? theme.colorScheme.primary : theme.colorScheme.surface);
    final foregroundColor = isActive 
        ? theme.colorScheme.onPrimary 
        : theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveBackgroundColor,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: foregroundColor),
            iconSize: 28,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    int? count,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: onTap,
                icon: Icon(icon, color: theme.colorScheme.onSurface),
                iconSize: 24,
                padding: const EdgeInsets.all(12),
              ),
            ),
            if (count != null && count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDangerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white),
            iconSize: 28,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompactButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? 
        (isActive ? theme.colorScheme.primary : theme.colorScheme.surface);
    final foregroundColor = backgroundColor != null
        ? Colors.white
        : (isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBackgroundColor,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: foregroundColor),
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}