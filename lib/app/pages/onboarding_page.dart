import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

/// Onboarding flow for new users with welcome, permissions, and setup
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      title: 'Welcome to WhatsApp Clone',
      subtitle: 'Connect with friends and family through messages and video calls',
      icon: Icons.waving_hand,
      color: Color(0xFF25D366),
    ),
    const OnboardingStep(
      title: 'Stay Connected',
      subtitle: 'Send messages, share photos, and make video calls seamlessly',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFF2196F3),
    ),
    const OnboardingStep(
      title: 'Permissions Required',
      subtitle: 'We need some permissions to provide the best experience',
      icon: Icons.security,
      color: Color(0xFFFF9800),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildOnboardingStep(step, index);
                },
              ),
            ),
            
            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? _steps[_currentPage].color
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text(
                          'Previous',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                    
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPage == _steps.length - 1
                          ? _handleGetStarted
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _steps[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(OnboardingStep step, int index) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: step.color,
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            step.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Special content for permissions step
          if (index == _steps.length - 1) ...[
            const SizedBox(height: 32),
            _buildPermissionsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsList() {
    return Column(
      children: [
        _buildPermissionItem(
          Icons.camera_alt,
          'Camera',
          'Take photos and record videos',
        ),
        _buildPermissionItem(
          Icons.mic,
          'Microphone',
          'Record audio for voice messages and calls',
        ),
        _buildPermissionItem(
          Icons.photo_library,
          'Photos',
          'Share images and videos from your gallery',
        ),
        _buildPermissionItem(
          Icons.contact_page,
          'Contacts',
          'Find friends who are using the app',
        ),
      ],
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleGetStarted() async {
    // Request permissions
    await _requestPermissions();
    
    // Navigate to auth
    if (mounted) {
      context.go('/auth');
    }
  }

  Future<void> _requestPermissions() async {
    // Request necessary permissions
    await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.contacts,
      Permission.notification,
    ].request();
  }
}

/// Data class for onboarding steps
class OnboardingStep {

  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}