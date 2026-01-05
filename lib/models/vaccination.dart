import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccination {
  final String? id;
  final String petId;
  final String vaccineName;
  final DateTime vaccinationDate;
  final DateTime? nextDate;
  final String? notes;
  final String status;
  final DateTime createdAt;

  Vaccination({
    this.id,
    required this.petId,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDate,
    this.notes,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'vaccineName': vaccineName,
      'vaccinationDate': Timestamp.fromDate(vaccinationDate),
      'nextDate': nextDate != null ? Timestamp.fromDate(nextDate!) : null,
      'notes': notes,
      'status': status, // 🆕
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Vaccination.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Vaccination(
      id: doc.id,
      petId: data['petId'] ?? '',
      vaccineName: data['vaccineName'] ?? '',
      vaccinationDate: (data['vaccinationDate'] as Timestamp).toDate(),
      nextDate: data['nextDate'] != null
          ? (data['nextDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      status: data['status'] ?? 'pending', // 🆕
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  bool canMarkAsCompleted() {
    if (nextDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDate = DateTime(
      nextDate!.year,
      nextDate!.month,
      nextDate!.day,
    );
    return scheduledDate.isBefore(today) ||
        scheduledDate.isAtSameMomentAs(today);
  }

  bool isDueSoon() {
    if (nextDate == null) return false;
    final now = DateTime.now();
    final difference = nextDate!.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }

  bool isOverdue() {
    if (nextDate == null) return false;
    return nextDate!.isBefore(DateTime.now());
  }
}
