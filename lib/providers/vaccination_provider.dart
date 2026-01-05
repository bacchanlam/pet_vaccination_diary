import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vaccination.dart';

class VaccinationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Vaccination> _vaccinations = [];
  bool _isLoading = false;

  List<Vaccination> get vaccinations => _vaccinations;
  bool get isLoading => _isLoading;

  // 🔥 SỬA: Load vaccinations CHỈ của pets thuộc user hiện tại
  Future<void> loadVaccinations() async {
    final user = _auth.currentUser;

    if (user == null) {
      print('❌ No user logged in');
      _vaccinations = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Bước 1: Lấy tất cả petIds của user
      final petsSnapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      final petIds = petsSnapshot.docs.map((doc) => doc.id).toList();

      print('🔍 User ${user.uid} has ${petIds.length} pets');

      if (petIds.isEmpty) {
        _vaccinations = [];
        print('📋 No pets found for this user');
      } else {
        // Bước 2: Lấy vaccinations của các pets này
        final vaccinationsSnapshot = await _firestore
            .collection('vaccinations')
            .where('petId', whereIn: petIds)
            .get();

        _vaccinations =
            vaccinationsSnapshot.docs
                .map((doc) => Vaccination.fromFirestore(doc))
                .toList()
              ..sort((a, b) => b.vaccinationDate.compareTo(a.vaccinationDate));

        print(
          '✅ Loaded ${_vaccinations.length} vaccinations for user ${user.uid}',
        );
      }
    } catch (e) {
      print('❌ Error loading vaccinations: $e');
      _vaccinations = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get vaccinations for a specific pet
  List<Vaccination> getVaccinationsForPet(String petId) {
    return _vaccinations.where((v) => v.petId == petId).toList()
      ..sort((a, b) => b.vaccinationDate.compareTo(a.vaccinationDate));
  }

  // Get upcoming vaccinations
  List<Vaccination> getUpcomingVaccinations() {
    final now = DateTime.now();
    return _vaccinations.where((v) {
      if (v.nextDate == null) return false;
      return v.nextDate!.isAfter(now) || v.nextDate!.isAtSameMomentAs(now);
    }).toList()..sort((a, b) => a.nextDate!.compareTo(b.nextDate!));
  }

  // Get overdue vaccinations
  List<Vaccination> getOverdueVaccinations() {
    return _vaccinations.where((v) => v.isOverdue()).toList();
  }

  // Add vaccination
  Future<bool> addVaccination(Vaccination vaccination) async {
    try {
      await _firestore.collection('vaccinations').add(vaccination.toMap());
      await loadVaccinations();
      return true;
    } catch (e) {
      print('Error adding vaccination: $e');
      return false;
    }
  }

  // Update vaccination
  Future<bool> updateVaccination(String id, Vaccination vaccination) async {
    try {
      await _firestore
          .collection('vaccinations')
          .doc(id)
          .update(vaccination.toMap());
      await loadVaccinations();
      return true;
    } catch (e) {
      print('Error updating vaccination: $e');
      return false;
    }
  }

  // Delete vaccination
  Future<bool> deleteVaccination(String id) async {
    try {
      await _firestore.collection('vaccinations').doc(id).delete();
      await loadVaccinations();
      return true;
    } catch (e) {
      print('Error deleting vaccination: $e');
      return false;
    }
  }

  Future<bool> markAsCompletedAndCreateNew({
    required String vaccinationId,
    required String newNotes,
    DateTime? customCompletionDate,
  }) async {
    try {
      final vaccinationDoc = await _firestore
          .collection('vaccinations')
          .doc(vaccinationId)
          .get();

      if (!vaccinationDoc.exists) {
        print('❌ Vaccination not found');
        return false;
      }

      final oldVaccination = Vaccination.fromFirestore(vaccinationDoc);

      // Bước 1: Cập nhật lịch cũ - RESET nextDate về null
      await _firestore.collection('vaccinations').doc(vaccinationId).update({
        'status': 'completed',
        'nextDate': null, // 🔥 XÓA ngày tiêm tiếp theo
        'notes': newNotes.isEmpty ? oldVaccination.notes : newNotes,
      });

      print('✅ Marked vaccination as completed and cleared nextDate');

      // Bước 2: Tạo bản ghi mới (clone)
      final completionDate = customCompletionDate ?? DateTime.now();

      final newVaccination = Vaccination(
        petId: oldVaccination.petId,
        vaccineName: oldVaccination.vaccineName,
        vaccinationDate: completionDate, // 🔥 Ngày tiêm = hôm nay
        nextDate: null, // 🔥 Chưa có lịch tiếp theo
        notes: newNotes.isEmpty ? null : newNotes,
        status: 'completed', // 🔥 Đã hoàn thành
        createdAt: DateTime.now(),
      );

      await _firestore.collection('vaccinations').add(newVaccination.toMap());

      print('✅ Created new vaccination record');

      // Reload danh sách
      await loadVaccinations();

      return true;
    } catch (e) {
      print('❌ Error marking as completed: $e');
      return false;
    }
  }
}
