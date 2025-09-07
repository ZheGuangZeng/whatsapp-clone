import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Removed unused imports

/// Calls and meetings history page
class CallsPage extends ConsumerWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_history',
                child: Text('Clear Call History'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Call Settings'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          _buildQuickActions(context),
          const Divider(height: 1),
          
          // Call History
          Expanded(
            child: _buildCallHistory(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewCallOptions(context),
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildQuickActionButton(
            context,
            Icons.video_call,
            'New Meeting',
            () => _createNewMeeting(context),
          ),
          const SizedBox(width: 16),
          _buildQuickActionButton(
            context,
            Icons.link,
            'Join Meeting',
            () => _showJoinMeetingDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildCallHistory(BuildContext context) {
    // TODO: Replace with actual call history from provider
    final mockCallHistory = _getMockCallHistory();

    if (mockCallHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No recent calls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Make your first video call!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: mockCallHistory.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final call = mockCallHistory[index];
        return _buildCallHistoryItem(context, call);
      },
    );
  }

  Widget _buildCallHistoryItem(BuildContext context, CallHistoryItem call) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCallStatusColor(call.status).withValues(alpha: 0.1),
        child: Icon(
          call.isVideoCall ? Icons.videocam : Icons.call,
          color: _getCallStatusColor(call.status),
        ),
      ),
      title: Text(
        call.participantName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            _getCallStatusIcon(call.status),
            size: 16,
            color: _getCallStatusColor(call.status),
          ),
          const SizedBox(width: 4),
          Text(
            _formatCallTime(call.timestamp, call.duration),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          call.isVideoCall ? Icons.videocam : Icons.call,
          color: const Color(0xFF25D366),
        ),
        onPressed: () => _initiateCall(context, call),
      ),
      onTap: () => _showCallDetails(context, call),
    );
  }

  Color _getCallStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.outgoing:
        return Colors.green;
      case CallStatus.incoming:
        return Colors.blue;
      case CallStatus.missed:
        return Colors.red;
      case CallStatus.rejected:
        return Colors.orange;
    }
  }

  IconData _getCallStatusIcon(CallStatus status) {
    switch (status) {
      case CallStatus.outgoing:
        return Icons.call_made;
      case CallStatus.incoming:
        return Icons.call_received;
      case CallStatus.missed:
        return Icons.call_received;
      case CallStatus.rejected:
        return Icons.call_end;
    }
  }

  String _formatCallTime(DateTime timestamp, Duration? duration) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    if (duration != null && duration.inSeconds > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$timeAgo • ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return timeAgo;
  }

  void _showSearch(BuildContext context) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search calls coming soon!')),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear_history':
        _showClearHistoryDialog(context);
        break;
      case 'settings':
        // TODO: Navigate to call settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call settings coming soon!')),
        );
        break;
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Call History'),
        content: const Text('Are you sure you want to clear all call history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Clear call history
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showNewCallOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Start a Call',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.video_call),
              title: const Text('New Meeting'),
              subtitle: const Text('Start an instant meeting'),
              onTap: () {
                Navigator.pop(context);
                _createNewMeeting(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Join with ID'),
              subtitle: const Text('Join a meeting using meeting ID'),
              onTap: () {
                Navigator.pop(context);
                _showJoinMeetingDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Call Contact'),
              subtitle: const Text('Call someone from your contacts'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show contact selection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact selection coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewMeeting(BuildContext context) {
    // TODO: Create and join new meeting
    final meetingId = 'meeting_${DateTime.now().millisecondsSinceEpoch}';
    context.push('/meeting/lobby/$meetingId');
  }

  void _showJoinMeetingDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Meeting'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter meeting ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final meetingId = controller.text.trim();
              if (meetingId.isNotEmpty) {
                Navigator.of(context).pop();
                context.push('/meeting/lobby/$meetingId');
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _initiateCall(BuildContext context, CallHistoryItem call) {
    // TODO: Initiate call with participant
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${call.participantName}...')),
    );
  }

  void _showCallDetails(BuildContext context, CallHistoryItem call) {
    // TODO: Show call details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call details coming soon!')),
    );
  }

  List<CallHistoryItem> _getMockCallHistory() {
    // TODO: Replace with real data from provider
    return [
      CallHistoryItem(
        participantName: 'John Doe',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 5, seconds: 30),
        status: CallStatus.outgoing,
        isVideoCall: true,
      ),
      CallHistoryItem(
        participantName: 'Jane Smith',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        duration: null,
        status: CallStatus.missed,
        isVideoCall: false,
      ),
      CallHistoryItem(
        participantName: 'Team Meeting',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        duration: const Duration(minutes: 45, seconds: 15),
        status: CallStatus.incoming,
        isVideoCall: true,
      ),
    ];
  }
}

/// Mock data classes for call history
class CallHistoryItem {
  final String participantName;
  final DateTime timestamp;
  final Duration? duration;
  final CallStatus status;
  final bool isVideoCall;

  CallHistoryItem({
    required this.participantName,
    required this.timestamp,
    required this.duration,
    required this.status,
    required this.isVideoCall,
  });
}

enum CallStatus {
  outgoing,
  incoming,
  missed,
  rejected,
}