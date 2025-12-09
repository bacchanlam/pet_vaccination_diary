import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vaccination.dart';

class VaccinationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Vaccination> _vaccinations = [];
  bool _isLoading = false;

  List<Vaccination> get vaccinations => _vaccinations;
  bool get isLoading => _isLoading;

  // Load all vaccinations
  Future<void> loadVaccinations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('vaccinations')
          .orderBy('vaccinationDate', descending: true)
          .get();

      _vaccinations = snapshot.docs
          .map((doc) => Vaccination.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading vaccinations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get vaccinations for a specific pet
  List<Vaccination> getVaccinationsForPet(String petId) {
    return _vaccinations
        .where((v) => v.petId == petId)
        .toList()
      ..sort((a, b) => b.vaccinationDate.compareTo(a.vaccinationDate));
  }

  // Get upcoming vaccinations
  List<Vaccination> getUpcomingVaccinations() {
    final now = DateTime.now();
    return _vaccinations.where((v) {
      if (v.nextDate == null) return false;
      return v.nextDate!.isAfter(now) || v.nextDate!.isAtSameMomentAs(now);
    }).toList()
      ..sort((a, b) => a.nextDate!.compareTo(b.nextDate!));
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
}
