import 'dart:io';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  static final ImageService instance = ImageService._init();
  
  ImageService._init();
  
  /// Download image to device gallery
  Future<bool> downloadImageToGallery(String imagePath) async {
    try {
      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }
      
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try photos permission for Android 13+
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            return false;
          }
        }
      }
      
      // Save to gallery using gal - it handles the album automatically
      await Gal.putImage(imagePath, album: 'StarLog');
      
      return true;
    } catch (e) {
      print('Error downloading image: $e');
      return false;
    }
  }
  
  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.photos.status;
      }
      return status.isGranted;
    }
    return true; // iOS handles permissions automatically
  }
  
  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    }
    return true;
  }
}
