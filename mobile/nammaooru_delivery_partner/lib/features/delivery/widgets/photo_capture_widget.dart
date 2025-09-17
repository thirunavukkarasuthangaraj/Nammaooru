import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoCaptureWidget extends StatefulWidget {
  final Function(File) onPhotoCaptured;
  final bool isEnabled;
  final String? hint;

  const PhotoCaptureWidget({
    Key? key,
    required this.onPhotoCaptured,
    this.isEnabled = true,
    this.hint,
  }) : super(key: key);

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _capturePhoto() async {
    if (!widget.isEnabled || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final File file = File(image.path);
        widget.onPhotoCaptured(file);
      }
    } catch (e) {
      _showErrorDialog('Error capturing photo: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _selectFromGallery() async {
    if (!widget.isEnabled || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final File file = File(image.path);
        widget.onPhotoCaptured(file);
      }
    } catch (e) {
      _showErrorDialog('Error selecting photo: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _capturePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _selectFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.isEnabled ? Colors.grey[400]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: widget.isEnabled ? Colors.grey[50] : Colors.grey[100],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isEnabled && !_isCapturing ? _showPhotoOptions : null,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCapturing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                const Text(
                  'Processing...',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: widget.isEnabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.hint ?? 'Tap to capture photo',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isEnabled ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Camera or Gallery',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isEnabled ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}