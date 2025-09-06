import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/meetings/presentation/widgets/participant_grid.dart';
import '../../features/meetings/presentation/widgets/meeting_controls.dart';

/// Meeting room page with participant grid and controls
class MeetingRoomPage extends ConsumerStatefulWidget {
  final String meetingId;
  
  const MeetingRoomPage({
    required this.meetingId,
    super.key,
  });

  @override
  ConsumerState<MeetingRoomPage> createState() => _MeetingRoomPageState();
}

class _MeetingRoomPageState extends ConsumerState<MeetingRoomPage> {
  bool _isControlsVisible = true;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isScreenSharing = false;
  
  // TODO: Replace with actual LiveKit room instance
  // For now we'll comment out the ParticipantGrid until LiveKit is properly integrated
  
  @override
  void initState() {
    super.initState();
    // Set landscape orientation for better meeting experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    
    // Auto-hide controls after 5 seconds
    _scheduleControlsAutoHide();
  }

  @override
  void dispose() {
    // Reset orientation when leaving meeting
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _scheduleControlsAutoHide() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isControlsVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _isControlsVisible = !_isControlsVisible);
          if (_isControlsVisible) {
            _scheduleControlsAutoHide();
          }
        },
        child: Stack(
          children: [
            // Participant Grid - TODO: Integrate with actual LiveKit
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Meeting Room',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'LiveKit integration pending',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Top Bar (Meeting Info)
            if (_isControlsVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),
            
            // Bottom Controls
            if (_isControlsVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(),
              ),
            
            // Side Panel (if needed)
            if (_isControlsVisible)
              _buildSidePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Meeting Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting ${widget.meetingId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '3 participants',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Top Actions
            Row(
              children: [
                _buildTopAction(
                  Icons.people,
                  () => _showParticipantsList(),
                ),
                const SizedBox(width: 12),
                _buildTopAction(
                  Icons.chat_bubble_outline,
                  () => _showChat(),
                ),
                const SizedBox(width: 12),
                _buildTopAction(
                  Icons.more_vert,
                  () => _showMoreOptions(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAction(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              isActive: !_isMuted,
              onPressed: () => setState(() => _isMuted = !_isMuted),
            ),
            
            // Video On/Off
            _buildControlButton(
              icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
              isActive: !_isVideoOff,
              onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
            ),
            
            // Screen Share
            _buildControlButton(
              icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              isActive: _isScreenSharing,
              onPressed: () => setState(() => _isScreenSharing = !_isScreenSharing),
              isSpecial: _isScreenSharing,
            ),
            
            // Speaker On/Off
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              isActive: _isSpeakerOn,
              onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
            ),
            
            // Leave Meeting
            _buildControlButton(
              icon: Icons.call_end,
              isActive: false,
              onPressed: () => _showLeaveConfirmation(),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    bool isSpecial = false,
    bool isDestructive = false,
  }) {
    Color backgroundColor;
    Color iconColor;
    
    if (isDestructive) {
      backgroundColor = Colors.red;
      iconColor = Colors.white;
    } else if (isSpecial && isActive) {
      backgroundColor = const Color(0xFF25D366);
      iconColor = Colors.white;
    } else if (isActive) {
      backgroundColor = Colors.white.withOpacity(0.2);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.red.withOpacity(0.8);
      iconColor = Colors.white;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    // This would be for chat or participants list overlay
    // For now, we'll keep it empty as we handle these with bottom sheets
    return const SizedBox.shrink();
  }

  void _showParticipantsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Participants (3)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Mock participants list
            ...List.generate(3, (index) => _buildParticipantListItem(
              'Participant ${index + 1}',
              index == 0, // First one is current user
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantListItem(String name, bool isCurrentUser) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF25D366).withOpacity(0.2),
        child: Text(
          name[0],
          style: const TextStyle(color: Color(0xFF25D366)),
        ),
      ),
      title: Text(
        isCurrentUser ? '$name (You)' : name,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrentUser) ...[
            Icon(
              Icons.mic,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.videocam,
            color: Colors.white70,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showChat() {
    // TODO: Implement in-meeting chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting chat coming soon!'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Meeting Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.record_voice_over, color: Colors.white70),
              title: const Text(
                'Start Recording',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _startRecording();
              },
            ),
            ListTile(
              leading: const Icon(Icons.blur_on, color: Colors.white70),
              title: const Text(
                'Background Blur',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleBackgroundBlur();
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.white70),
              title: const Text(
                'Meeting Security',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSecurityOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording started'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  void _toggleBackgroundBlur() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Background blur toggled'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  void _showSecurityOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security options coming soon!'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Leave Meeting',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave this meeting?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveMeeting();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _leaveMeeting() {
    // TODO: Implement actual meeting leave with LiveKit
    context.pop();
  }
}