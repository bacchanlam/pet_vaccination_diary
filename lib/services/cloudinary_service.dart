import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String cloudName = 'duz06xaog';
  static const String uploadPreset = 'pet_images';

  final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  Future<String?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'pet_images',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final fileName = pathSegments.last;
        return fileName.split('.').first;
      }
      return null;
    } catch (e) {
      print('Error parsing URL: $e');
      return null;
    }
  }
}
