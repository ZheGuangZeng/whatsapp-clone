import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_entity.dart';
import '../providers/file_providers.dart';

/// Widget for previewing files
class FilePreviewWidget extends ConsumerWidget {
  const FilePreviewWidget({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.onTap,
    this.showFileName = true,
    this.showFileSize = true,
    this.showDownloadButton = true,
  });

  /// The file to preview
  final FileEntity file;

  /// Width of the preview
  final double? width;

  /// Height of the preview
  final double? height;

  /// Border radius for the preview
  final double borderRadius;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Whether to show file name
  final bool showFileName;

  /// Whether to show file size
  final bool showFileSize;

  /// Whether to show download button
  final bool showDownloadButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File preview
              Expanded(
                child: _buildFilePreview(context, ref),
              ),
              
              // File info
              if (showFileName || showFileSize) ...[
                const SizedBox(height: 8),
                _buildFileInfo(context),
              ],
              
              // Actions
              if (showDownloadButton) ...[
                const SizedBox(height: 8),
                _buildActions(context, ref),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, WidgetRef ref) {
    switch (file.fileType) {
      case FileType.image:
        return _ImagePreview(file: file);
      
      case FileType.video:
        return _VideoPreview(file: file);
      
      case FileType.audio:
        return _AudioPreview(file: file);
      
      case FileType.document:
        return _DocumentPreview(file: file);
      
      case FileType.other:
        return _GenericFilePreview(file: file);
    }
  }

  Widget _buildFileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFileName)
          Text(
            file.originalName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (showFileSize) ...[
          const SizedBox(height: 4),
          Text(
            file.formattedSize,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => _downloadFile(context, ref),
          icon: const Icon(Icons.download, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            foregroundColor: Theme.of(context).primaryColor,
            minimumSize: const Size(32, 32),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadFile(BuildContext context, WidgetRef ref) async {
    try {
      final downloadUseCase = ref.read(downloadFileUseCaseProvider);
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await downloadUseCase(DownloadFileParams(
        fileEntity: file,
      ));

      // Hide loading indicator
      Navigator.of(context).pop();

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${failure.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (downloadedFile) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded to: ${downloadedFile.path}'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Image preview widget
class _ImagePreview extends ConsumerWidget {
  const _ImagePreview({required this.file});

  final FileEntity file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileUrlsNotifier = ref.watch(fileUrlsProvider.notifier);

    return FutureBuilder<String?>(
      future: fileUrlsNotifier.getFileUrl(file),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }
}

/// Video preview widget
class _VideoPreview extends ConsumerWidget {
  const _VideoPreview({required this.file});

  final FileEntity file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (file.hasThumbnail) {
      // Show thumbnail with play button overlay
      final fileUrlsNotifier = ref.watch(fileUrlsProvider.notifier);
      
      return FutureBuilder<String?>(
        future: fileUrlsNotifier.getFileUrl(file.copyWith(storagePath: file.thumbnailPath!)),
        builder: (context, snapshot) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (snapshot.hasData)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              else
                Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.videocam, size: 48, color: Colors.grey),
                  ),
                ),
              
              // Play button overlay
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          );
        },
      );
    }

    // No thumbnail available
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Video File', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// Audio preview widget
class _AudioPreview extends StatelessWidget {
  const _AudioPreview({required this.file});

  final FileEntity file;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 48),
            SizedBox(height: 8),
            Text('Audio File'),
          ],
        ),
      ),
    );
  }
}

/// Document preview widget
class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.file});

  final FileEntity file;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;

    switch (file.extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        label = 'PDF Document';
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        label = 'Word Document';
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        label = 'Excel Spreadsheet';
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        label = 'PowerPoint Presentation';
        break;
      default:
        icon = Icons.description;
        label = 'Document';
    }

    return Container(
      color: Colors.blue.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.blue.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic file preview widget
class _GenericFilePreview extends StatelessWidget {
  const _GenericFilePreview({required this.file});

  final FileEntity file;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'File',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}