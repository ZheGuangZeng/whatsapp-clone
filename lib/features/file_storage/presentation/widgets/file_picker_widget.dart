import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/file_entity.dart';
import '../providers/file_providers.dart';
import '../../domain/usecases/upload_file_usecase.dart';

/// Widget for picking and uploading files
class FilePickerWidget extends ConsumerStatefulWidget {
  const FilePickerWidget({
    super.key,
    required this.bucket,
    this.onFileUploaded,
    this.onUploadProgress,
    this.allowedTypes,
    this.maxFileSize,
    this.compressionQuality = 80,
    this.generateThumbnail = true,
    this.showPreview = true,
  });

  /// Storage bucket to upload to
  final String bucket;

  /// Callback when file is successfully uploaded
  final Function(FileEntity)? onFileUploaded;

  /// Callback for upload progress
  final Function(UploadProgressEntity)? onUploadProgress;

  /// Allowed file extensions
  final List<String>? allowedTypes;

  /// Maximum file size in bytes
  final int? maxFileSize;

  /// Image compression quality (0-100)
  final int compressionQuality;

  /// Whether to generate thumbnails
  final bool generateThumbnail;

  /// Whether to show file preview
  final bool showPreview;

  @override
  ConsumerState<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends ConsumerState<FilePickerWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;
  UploadProgressEntity? _uploadProgress;

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      // Check camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        _showError('Camera permission denied');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: widget.compressionQuality,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _uploadError = null;
        });

        if (widget.showPreview) {
          _showPreviewDialog();
        } else {
          await _uploadFile();
        }
      }
    } catch (e) {
      _showError('Failed to pick image from camera: ${e.toString()}');
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      // Check photo permission
      final photoPermission = await Permission.photos.request();
      if (!photoPermission.isGranted) {
        _showError('Photos permission denied');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: widget.compressionQuality,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _uploadError = null;
        });

        if (widget.showPreview) {
          _showPreviewDialog();
        } else {
          await _uploadFile();
        }
      }
    } catch (e) {
      _showError('Failed to pick image from gallery: ${e.toString()}');
    }
  }

  /// Pick file from storage
  Future<void> _pickFile() async {
    try {
      // Check storage permission
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted) {
        _showError('Storage permission denied');
        return;
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedTypes ?? [
          ...AppConstants.supportedImageTypes,
          ...AppConstants.supportedVideoTypes,
          ...AppConstants.supportedAudioTypes,
          ...AppConstants.supportedDocumentTypes,
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Validate file size
        final fileStats = await file.stat();
        final maxSize = widget.maxFileSize ?? _getMaxSizeForBucket();
        
        if (fileStats.size > maxSize) {
          _showError('File size exceeds limit of ${(maxSize / (1024 * 1024)).toStringAsFixed(1)} MB');
          return;
        }

        setState(() {
          _selectedFile = file;
          _uploadError = null;
        });

        if (widget.showPreview) {
          _showPreviewDialog();
        } else {
          await _uploadFile();
        }
      }
    } catch (e) {
      _showError('Failed to pick file: ${e.toString()}');
    }
  }

  /// Upload the selected file
  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
      _uploadProgress = null;
    });

    try {
      final uploadFileUseCase = ref.read(uploadFileUseCaseProvider);
      
      final result = await uploadFileUseCase(UploadFileParams(
        file: _selectedFile!,
        bucket: widget.bucket,
        compressionQuality: widget.compressionQuality,
        generateThumbnail: widget.generateThumbnail,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
          widget.onUploadProgress?.call(progress);
        },
      ));

      result.fold(
        (failure) {
          setState(() {
            _isUploading = false;
            _uploadError = failure.toString();
          });
        },
        (fileEntity) {
          setState(() {
            _isUploading = false;
            _selectedFile = null;
            _uploadProgress = null;
          });
          
          widget.onFileUploaded?.call(fileEntity);
          _showSuccessMessage('File uploaded successfully');
        },
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = e.toString();
      });
    }
  }

  /// Show file preview dialog
  void _showPreviewDialog() {
    if (_selectedFile == null) return;

    showDialog(
      context: context,
      builder: (context) => FilePreviewDialog(
        file: _selectedFile!,
        onUpload: _uploadFile,
        onCancel: () {
          setState(() {
            _selectedFile = null;
          });
          Navigator.of(context).pop();
        },
        isUploading: _isUploading,
        uploadProgress: _uploadProgress,
        uploadError: _uploadError,
      ),
    );
  }

  /// Get maximum file size for current bucket
  int _getMaxSizeForBucket() {
    switch (widget.bucket) {
      case AppConstants.userAvatarsBucket:
        return AppConstants.maxAvatarSize;
      case AppConstants.messageAttachmentsBucket:
        return AppConstants.maxAttachmentSize;
      case AppConstants.chatMediaBucket:
      default:
        return AppConstants.maxChatMediaSize;
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FilePickerButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onPressed: _isUploading ? null : _pickFromCamera,
            ),
            _FilePickerButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onPressed: _isUploading ? null : _pickFromGallery,
            ),
            _FilePickerButton(
              icon: Icons.attach_file,
              label: 'File',
              onPressed: _isUploading ? null : _pickFile,
            ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          if (_uploadProgress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _uploadProgress!.progress / 100,
            ),
            const SizedBox(height: 4),
            Text(
              '${_uploadProgress!.progress.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
        if (_uploadError != null) ...[
          const SizedBox(height: 16),
          Text(
            _uploadError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Button for file picker options
class _FilePickerButton extends StatelessWidget {
  const _FilePickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            foregroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Dialog for previewing file before upload
class FilePreviewDialog extends StatelessWidget {
  const FilePreviewDialog({
    super.key,
    required this.file,
    required this.onUpload,
    required this.onCancel,
    required this.isUploading,
    this.uploadProgress,
    this.uploadError,
  });

  final File file;
  final VoidCallback onUpload;
  final VoidCallback onCancel;
  final bool isUploading;
  final UploadProgressEntity? uploadProgress;
  final String? uploadError;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final fileType = FileType.fromExtension(extension);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildFilePreview(fileType),
            ),
            const SizedBox(height: 16),
            
            // File info
            Text(
              fileName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Upload progress
            if (isUploading && uploadProgress != null) ...[
              LinearProgressIndicator(
                value: uploadProgress!.progress / 100,
              ),
              const SizedBox(height: 8),
              Text('${uploadProgress!.progress.toStringAsFixed(1)}%'),
            ],
            
            // Upload error
            if (uploadError != null) ...[
              Text(
                uploadError!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: isUploading ? null : onCancel,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : onUpload,
                  child: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 48),
              );
            },
          ),
        );
      
      case FileType.video:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 48),
              SizedBox(height: 8),
              Text('Video File'),
            ],
          ),
        );
      
      case FileType.audio:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack, size: 48),
              SizedBox(height: 8),
              Text('Audio File'),
            ],
          ),
        );
      
      case FileType.document:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 48),
              SizedBox(height: 8),
              Text('Document'),
            ],
          ),
        );
      
      case FileType.other:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file, size: 48),
              SizedBox(height: 8),
              Text('File'),
            ],
          ),
        );
    }
  }
}