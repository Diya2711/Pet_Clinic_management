import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new pet
  Future<Pet> addPet(Pet pet) async {
    try {
      final docRef = await _firestore.collection('pets').add(pet.toMap());
      final updatedPet = Pet(
        id: docRef.id,
        ownerId: pet.ownerId,
        name: pet.name,
        type: pet.type,
        breed: pet.breed,
        dateOfBirth: pet.dateOfBirth,
        gender: pet.gender,
        weight: pet.weight,
        medicalHistory: pet.medicalHistory,
        photoUrl: pet.photoUrl,
      );

      // Update the pet document with the generated ID
      await docRef.update({'id': docRef.id});

      return updatedPet;
    } catch (e) {
      throw Exception('Failed to add pet: $e');
    }
  }

  // Get a pet by ID
  Future<Pet> getPet(String petId) async {
    try {
      final doc = await _firestore.collection('pets').doc(petId).get();
      if (!doc.exists) {
        throw Exception('Pet not found');
      }
      return Pet.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get pet: $e');
    }
  }

  // Get all pets for a user
  Future<List<Pet>> getUserPets(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) => Pet.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get user pets: $e');
    }
  }

  // Update a pet
  Future<void> updatePet(Pet pet) async {
    try {
      await _firestore.collection('pets').doc(pet.id).update(pet.toMap());
    } catch (e) {
      throw Exception('Failed to update pet: $e');
    }
  }

  // Delete a pet
  Future<void> deletePet(String petId) async {
    try {
      await _firestore.collection('pets').doc(petId).delete();
    } catch (e) {
      throw Exception('Failed to delete pet: $e');
    }
  }

  // Add a medical record to a pet
  Future<void> addMedicalRecord(String petId, MedicalRecord record) async {
    try {
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (!petDoc.exists) {
        throw Exception('Pet not found');
      }

      final pet = Pet.fromMap(petDoc.data()!);
      final updatedMedicalHistory = [...pet.medicalHistory, record];

      await _firestore.collection('pets').doc(petId).update({
        'medicalHistory': updatedMedicalHistory.map((r) => r.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add medical record: $e');
    }
  }

  // Get medical history for a pet
  Future<List<MedicalRecord>> getMedicalHistory(String petId) async {
    try {
      final pet = await getPet(petId);
      return pet.medicalHistory;
    } catch (e) {
      throw Exception('Failed to get medical history: $e');
    }
  }

  // Update a medical record
  Future<void> updateMedicalRecord(
      String petId, String recordId, MedicalRecord updatedRecord) async {
    try {
      final pet = await getPet(petId);
      final updatedMedicalHistory = pet.medicalHistory.map((record) {
        return record.id == recordId ? updatedRecord : record;
      }).toList();

      await _firestore.collection('pets').doc(petId).update({
        'medicalHistory': updatedMedicalHistory.map((r) => r.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update medical record: $e');
    }
  }

  // Delete a medical record
  Future<void> deleteMedicalRecord(String petId, String recordId) async {
    try {
      final pet = await getPet(petId);
      final updatedMedicalHistory =
          pet.medicalHistory.where((record) => record.id != recordId).toList();

      await _firestore.collection('pets').doc(petId).update({
        'medicalHistory': updatedMedicalHistory.map((r) => r.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to delete medical record: $e');
    }
  }
}
