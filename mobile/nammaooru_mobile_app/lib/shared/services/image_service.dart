import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  static Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }
  
  static Future<File?> pickImageFromCamera({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) return null;
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? AppConstants.imageQuality,
      );
      
      if (image != null) {
        return File(image.path);
      }
      
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }
  
  static Future<File?> pickImageFromGallery({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) return null;
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? AppConstants.imageQuality,
      );
      
      if (image != null) {
        return File(image.path);
      }
      
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }
  
  static Future<List<File>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) return [];
      
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? AppConstants.imageQuality,
      );
      
      if (limit != null && images.length > limit) {
        return images.take(limit).map((image) => File(image.path)).toList();
      }
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
  
  static Future<File?> cropImage(
    File imageFile, {
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? aspectRatioPresets,
    CropStyle cropStyle = CropStyle.rectangle,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: aspectRatio,
        // aspectRatioPresets: aspectRatioPresets ?? [
        //   CropAspectRatioPreset.original,
        //   CropAspectRatioPreset.square,
        //   CropAspectRatioPreset.ratio3x2,
        //   CropAspectRatioPreset.ratio4x3,
        //   CropAspectRatioPreset.ratio16x9,
        // ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );
      
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      
      return null;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }
  
  static Future<bool> isValidImageSize(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      return fileSize <= AppConstants.maxImageSize;
    } catch (e) {
      print('Error checking image size: $e');
      return false;
    }
  }
  
  static Future<File?> compressImage(
    File imageFile, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // This is a placeholder implementation
      // In a real app, you might use packages like flutter_image_compress
      return imageFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
  
  static Future<File?> saveImageToCache(Uint8List imageBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      print('Error saving image to cache: $e');
      return null;
    }
  }
  
  static Future<void> deleteImageFile(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print('Error deleting image file: $e');
    }
  }
  
  static Future<void> showImagePickerDialog(
    BuildContext context, {
    required Function(File) onImageSelected,
    bool allowMultiple = false,
    bool allowCropping = true,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePickerOption(
                      context,
                      'Camera',
                      Icons.camera_alt,
                      () async {
                        Navigator.pop(context);
                        final image = await pickImageFromCamera();
                        if (image != null) {
                          if (allowCropping) {
                            final croppedImage = await cropImage(image);
                            if (croppedImage != null) {
                              onImageSelected(croppedImage);
                            }
                          } else {
                            onImageSelected(image);
                          }
                        }
                      },
                    ),
                    _buildImagePickerOption(
                      context,
                      'Gallery',
                      Icons.photo_library,
                      () async {
                        Navigator.pop(context);
                        if (allowMultiple) {
                          final images = await pickMultipleImages();
                          if (images.isNotEmpty) {
                            for (final image in images) {
                              onImageSelected(image);
                            }
                          }
                        } else {
                          final image = await pickImageFromGallery();
                          if (image != null) {
                            if (allowCropping) {
                              final croppedImage = await cropImage(image);
                              if (croppedImage != null) {
                                onImageSelected(croppedImage);
                              }
                            } else {
                              onImageSelected(image);
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  static Widget _buildImagePickerOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}