import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Thay thông tin của bạn vào đây
  static const String cloudName = 'duz06xaog'; // VD: 'demo'
  static const String uploadPreset = 'pet_images'; // VD: 'pet_images'
  
  final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  // Upload ảnh lên Cloudinary
  Future<String?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'pet_images', // Tạo folder trong Cloudinary
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      // Trả về URL của ảnh
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Lấy public ID từ URL (nếu cần xóa thủ công trên Cloudinary Dashboard)
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