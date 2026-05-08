import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/models/scooter_model.dart';

class MotorcycleCatalogService {
  const MotorcycleCatalogService._();

  static const MotorcycleCatalogService instance = MotorcycleCatalogService._();
  static const String collectionPath = 'motorcycleCategories';

  Stream<List<ScooterModel>> watchModels() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(ScooterCatalog.models);
    }
    return FirebaseFirestore.instance
        .collection(collectionPath)
        .snapshots()
        .map((snapshot) {
          final communityModels = snapshot.docs
              .map((doc) => ScooterModel.fromMap(doc.data()))
              .where((model) => model.id.isNotEmpty)
              .toList();
          return ScooterCatalog.mergeWith(communityModels);
        });
  }

  Future<ScooterModel?> findById(String? id) async {
    final builtIn = ScooterCatalog.findById(id);
    if (builtIn != null || id == null || id.trim().isEmpty) {
      return builtIn;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(id)
        .get();
    if (!snapshot.exists) {
      return null;
    }
    return ScooterModel.fromMap(snapshot.data() ?? <String, dynamic>{});
  }

  Future<ScooterModel> addMotorcycle({
    required String brand,
    required String name,
    required int displacementCc,
    required String description,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw const MotorcycleCatalogException(
        'Firebase is not ready yet. Restart the app and try again.',
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const MotorcycleCatalogException(
        'Sign in with Google before adding a motorcycle category.',
      );
    }

    final cleanBrand = _cleanRequired(brand, 'Brand');
    final cleanName = _cleanRequired(name, 'Model');
    final cleanDescription = description.trim();
    if (displacementCc < 50 || displacementCc > 2000) {
      throw const MotorcycleCatalogException(
        'Enter a valid engine size from 50cc to 2000cc.',
      );
    }
    if (cleanDescription.length > 180) {
      throw const MotorcycleCatalogException(
        'Keep the description under 180 characters.',
      );
    }

    final model = ScooterModel(
      id: ScooterCatalog.idFor(
        brand: cleanBrand,
        name: cleanName,
        displacementCc: displacementCc,
      ),
      brand: cleanBrand,
      name: cleanName,
      displacementCc: displacementCc,
      description: cleanDescription.isEmpty ? null : cleanDescription,
      communityCreated: true,
    );

    final ref = FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(model.id);
    final existing = await ref.get();
    if (existing.exists) {
      return ScooterModel.fromMap(existing.data() ?? <String, dynamic>{});
    }

    await ref.set({
      ...model.toMap(),
      'createdBy': user.uid,
      'createdByName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return model;
  }

  String _cleanRequired(String value, String label) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      throw MotorcycleCatalogException('$label is required.');
    }
    return cleaned;
  }
}

class MotorcycleCatalogException implements Exception {
  const MotorcycleCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}
