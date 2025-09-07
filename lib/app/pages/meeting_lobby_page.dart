import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Removed unused livekit import

/// Meeting lobby page with preview and settings
class MeetingLobbyPage extends ConsumerStatefulWidget {
  final String meetingId;
  
  const MeetingLobbyPage({
    required this.meetingId,
    super.key,
  });

  @override
  ConsumerState<MeetingLobbyPage> createState() => _MeetingLobbyPageState();
}

class _MeetingLobbyPageState extends ConsumerState<MeetingLobbyPage> {
  bool _isCameraEnabled = true;
  bool _isMicEnabled = true;
  bool _isJoining = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Meeting ID: ${widget.meetingId}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showMeetingSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF25D366).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: _buildCameraPreview(),
            ),
          ),
          
          // Meeting Info
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Ready to join?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your camera and microphone before joining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Audio/Video Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                      isEnabled: _isCameraEnabled,
                      onPressed: () => setState(() => _isCameraEnabled = !_isCameraEnabled),
                      label: 'Camera',
                    ),
                    _buildControlButton(
                      icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
                      isEnabled: _isMicEnabled,
                      onPressed: () => setState(() => _isMicEnabled = !_isMicEnabled),
                      label: 'Microphone',
                    ),
                    _buildControlButton(
                      icon: Icons.cameraswitch,
                      isEnabled: true,
                      onPressed: () => _switchCamera(),
                      label: 'Switch',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Join Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : () => _joinMeeting(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Join Meeting',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Alternative Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _shareMeetingLink(),
                      icon: const Icon(Icons.share, color: Colors.white70),
                      label: const Text(
                        'Share Link',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 24),
                    TextButton.icon(
                      onPressed: () => _copyMeetingId(),
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      label: const Text(
                        'Copy ID',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera is off',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // TODO: Implement actual camera preview using LiveKit
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.withValues(alpha: 0.3),
            Colors.green.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 64,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Camera Preview',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '(Will show actual feed in production)',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Mirror toggle (for front camera)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showMeetingSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Meeting Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.blur_on, color: Colors.white70),
              title: const Text(
                'Background Blur',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: false,
                onChanged: (value) => Navigator.pop(context),
                activeTrackColor: const Color(0xFF25D366),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.hd, color: Colors.white70),
              title: const Text(
                'HD Quality',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) => Navigator.pop(context),
                activeTrackColor: const Color(0xFF25D366),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchCamera() {
    // TODO: Implement camera switching
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera switched'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  Future<void> _joinMeeting() async {
    setState(() => _isJoining = true);
    
    try {
      // TODO: Implement actual meeting join with LiveKit
      await Future<void>.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.pushReplacement('/meeting/room/${widget.meetingId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join meeting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _shareMeetingLink() {
    // TODO: Implement meeting link sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting link copied to clipboard'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  void _copyMeetingId() {
    // TODO: Copy meeting ID to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting ID copied to clipboard'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }
}