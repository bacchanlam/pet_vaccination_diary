import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Pet> _pets = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;

  // Load all pets
  Future<void> loadPets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .get();

      _pets = snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading pets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new pet
  Future<bool> addPet(Pet pet) async {
    try {
      await _firestore.collection('pets').add(pet.toMap());
      await loadPets();
      return true;
    } catch (e) {
      print('Error adding pet: $e');
      return false;
    }
  }

  // Update pet
  Future<bool> updatePet(String id, Pet pet) async {
    try {
      await _firestore.collection('pets').doc(id).update(pet.toMap());
      await loadPets();
      return true;
    } catch (e) {
      print('Error updating pet: $e');
      return false;
    }
  }

  // Delete pet
  Future<bool> deletePet(String id) async {
    try {
      // Delete pet
      await _firestore.collection('pets').doc(id).delete();
      
      // Delete all vaccinations for this pet
      final vaccinations = await _firestore
          .collection('vaccinations')
          .where('petId', isEqualTo: id)
          .get();
      
      for (var doc in vaccinations.docs) {
        await doc.reference.delete();
      }
      
      await loadPets();
      return true;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }

  // Get pet by ID
  Pet? getPetById(String id) {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }
}