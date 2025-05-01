import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isFullScreen = true;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: color2,
        body: Stack(
          children: [
            // Image with zoom capability
            GestureDetector(
              onTap: _toggleFullScreen,
              child: Center(
                child: Hero(
                  tag: widget.heroTag ?? widget.imageUrl,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white70,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Failed to load image",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Close and action buttons
            AnimatedOpacity(
              opacity: _isFullScreen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    // Top bar with close button
                    Container(
                      padding: EdgeInsets.only(left: 8, right: 8),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _resetTransformation,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                tooltip: 'Reset Zoom',
                              ),
                              IconButton(
                                onPressed: () => _saveImage(context),
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                                tooltip: 'Save Image',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _resetTransformation() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _saveImage(BuildContext context) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Request storage permission
      final status = await _requestPermission();
      if (!status) {
        _showSnackBar(context, 'Storage permission denied', isError: true);
        return;
      }

      // Show a downloading indicator
      _showSnackBar(context, 'Downloading image...');

      // Download image from URL
      final http.Response response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Get file name from URL
      final String fileName = path.basename(widget.imageUrl);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileNameWithTimestamp = '${timestamp}_$fileName';

      // Get the download directory
      final Directory? directory = Platform.isAndroid
          ? await getExternalStorageDirectory() // For Android
          : await getApplicationDocumentsDirectory(); // For iOS

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // If Android, move to the Pictures directory
      final String savePath = Platform.isAndroid
          ? '/storage/emulated/0/Pictures/Finmate'
          : directory.path;

      // Create directory if it doesn't exist
      final Directory saveDir = Directory(savePath);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Save file
      final String filePath = '${savePath}/$fileNameWithTimestamp';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _showSnackBar(context, 'Image saved to Pictures/Finmate');
    } catch (e) {
      _showSnackBar(context, 'Failed to save image: $e', isError: true);
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      // For Android 13 (API level 33) and above
      if (await Permission.photos.request().isGranted) {
        return true;
      }

      // For older Android versions
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit permission for saving to app directory
      return true;
    } else {
      // For other platforms (e.g., web, desktop), handle accordingly
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : color3,
        duration: Duration(seconds: 2),
        action: isError
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }
}
