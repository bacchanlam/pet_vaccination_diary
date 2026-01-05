import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String? id;
  final String userId;
  final String name;
  final String type;
  final String breed;
  final String gender;
  final DateTime birthDate;
  final String? imageUrl;
  final DateTime createdAt;

  Pet({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.breed,
    required this.gender,
    required this.birthDate,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'breed': breed,
      'gender': gender,
      'birthDate': Timestamp.fromDate(birthDate),
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      gender: data['gender'] ?? 'Đực',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  String getAge() {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years tuổi ${months > 0 ? '$months tháng' : ''}';
    } else if (months > 0) {
      return '$months tháng';
    } else {
      return '${difference.inDays} ngày';
    }
  }
}
