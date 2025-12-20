import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';

class PetProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Pet> _pets = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;

  // Load pets của user hiện tại
  Future<void> loadPets() async {
    final user = _auth.currentUser;
    
    print('🔍 Current user: ${user?.uid}');
    
    if (user == null) {
      print('❌ No user logged in');
      _pets = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Lấy pets của user (không dùng orderBy để tránh lỗi index)
      final snapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      _pets = snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();
      
      // Sort trong code
      _pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ Loaded ${_pets.length} pets');
    } catch (e) {
      print('❌ Error loading pets: $e');
      _pets = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new pet
  Future<bool> addPet(Pet pet) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return false;
    }

    try {
      final petWithUserId = Pet(
        userId: user.uid,
        name: pet.name,
        type: pet.type,
        breed: pet.breed,
        gender: pet.gender,
        birthDate: pet.birthDate,
        imageUrl: pet.imageUrl,
        createdAt: DateTime.now(), // 🔥 Đảm bảo có createdAt mới
      );

      await _firestore.collection('pets').add(petWithUserId.toMap());
      
      print('✅ Pet added successfully');
      
      // Reload pets sau khi thêm
      await loadPets();
      
      return true;
    } catch (e) {
      print('❌ Error adding pet: $e');
      return false;
    }
  }

  // Update pet
  Future<bool> updatePet(String id, Pet pet) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Kiểm tra quyền sở hữu
      final petDoc = await _firestore.collection('pets').doc(id).get();
      if (!petDoc.exists) return false;

      final existingPet = Pet.fromFirestore(petDoc);
      if (existingPet.userId != user.uid) {
        print('❌ Permission denied');
        return false;
      }

      // Update với userId cũ
      final petWithUserId = Pet(
        userId: existingPet.userId,
        name: pet.name,
        type: pet.type,
        breed: pet.breed,
        gender: pet.gender,
        birthDate: pet.birthDate,
        imageUrl: pet.imageUrl,
        createdAt: existingPet.createdAt, // 🔥 Giữ nguyên createdAt cũ
      );

      await _firestore.collection('pets').doc(id).update(petWithUserId.toMap());
      await loadPets();
      
      return true;
    } catch (e) {
      print('❌ Error updating pet: $e');
      return false;
    }
  }

  // Delete pet
  Future<bool> deletePet(String id) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Kiểm tra quyền sở hữu
      final petDoc = await _firestore.collection('pets').doc(id).get();
      if (!petDoc.exists) return false;

      final existingPet = Pet.fromFirestore(petDoc);
      if (existingPet.userId != user.uid) {
        print('❌ Permission denied');
        return false;
      }

      // Xóa pet
      await _firestore.collection('pets').doc(id).delete();
      
      // Xóa tất cả vaccinations
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
      print('❌ Error deleting pet: $e');
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