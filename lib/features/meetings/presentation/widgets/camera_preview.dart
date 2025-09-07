import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget for showing camera preview in meeting lobby
class CameraPreview extends StatefulWidget {
  const CameraPreview({
    required this.isEnabled,
    this.onCameraToggle,
    this.onCameraSwitch,
    super.key,
  });
  
  final bool isEnabled;
  final VoidCallback? onCameraToggle;
  final VoidCallback? onCameraSwitch;
  
  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  LocalVideoTrack? _localVideoTrack;
  CameraPosition _currentCameraPosition = CameraPosition.front;
  bool _isInitializing = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  @override
  void didUpdateWidget(CameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isEnabled != widget.isEnabled) {
      if (widget.isEnabled) {
        _enableCamera();
      } else {
        _disableCamera();
      }
    }
  }
  
  @override
  void dispose() {
    _localVideoTrack?.stop();
    _localVideoTrack?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    if (!widget.isEnabled) {
      setState(() => _isInitializing = false);
      return;
    }
    
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      
      if (cameraPermission != PermissionStatus.granted) {
        setState(() {
          _error = 'Camera permission denied';
          _isInitializing = false;
        });
        return;
      }
      
      await _enableCamera();
      
    } catch (error) {
      setState(() {
        _error = 'Failed to initialize camera: $error';
        _isInitializing = false;
      });
    }
  }
  
  Future<void> _enableCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _error = null;
      });
      
      // Stop existing track if any
      await _localVideoTrack?.stop();
      _localVideoTrack?.dispose();
      
      // Create new camera video track
      _localVideoTrack = await LocalVideoTrack.createCameraTrack(
        const CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          params: VideoParametersPresets.h720_169,
        ),
      );
      
      setState(() => _isInitializing = false);
      
    } catch (error) {
      setState(() {
        _error = 'Failed to enable camera: $error';
        _isInitializing = false;
      });
    }
  }
  
  Future<void> _disableCamera() async {
    await _localVideoTrack?.stop();
    _localVideoTrack?.dispose();
    _localVideoTrack = null;
    setState(() {});
  }
  
  Future<void> _switchCamera() async {
    if (_localVideoTrack == null) return;
    
    try {
      // Switch camera position
      final newPosition = _currentCameraPosition == CameraPosition.front 
          ? CameraPosition.back 
          : CameraPosition.front;
      
      await _localVideoTrack?.setCameraPosition(newPosition);
      
      setState(() => _currentCameraPosition = newPosition);
      
      widget.onCameraSwitch?.call();
      
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return _buildCameraDisabled();
    }
    
    if (_isInitializing) {
      return _buildLoading();
    }
    
    if (_error != null) {
      return _buildError();
    }
    
    if (_localVideoTrack == null) {
      return _buildCameraDisabled();
    }
    
    return _buildCameraPreview();
  }
  
  Widget _buildCameraPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video preview
            VideoTrackRenderer(
              _localVideoTrack!,
            ),
            
            // Camera switch button
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 40,
                  height: 40,
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
            ),
            
            // Camera position indicator
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentCameraPosition == CameraPosition.front 
                      ? 'Front Camera'
                      : 'Back Camera',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraDisabled() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 48,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
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
  
  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF25D366),
          ),
          SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildError() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Camera error',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}