import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/ride_model.dart';
import '../data/models/scooter_model.dart';
import 'mapbox_service.dart';
import 'motorcycle_catalog_service.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.rideId,
    required this.placeName,
    required this.weekId,
    required this.motorModelId,
    required this.motorModelName,
    required this.motorBrand,
    required this.topSpeedKmh,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.updatedAt,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final String rideId;
  final String placeName;
  final String weekId;
  final String motorModelId;
  final String motorModelName;
  final String motorBrand;
  final double topSpeedKmh;
  final double distanceMeters;
  final int durationSeconds;
  final DateTime? updatedAt;

  factory LeaderboardEntry.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? const {};
    return LeaderboardEntry(
      userId: (data['userId'] as String?) ?? snapshot.id,
      displayName: (data['displayName'] as String?) ?? 'Rydar Rider',
      photoUrl: data['photoUrl'] as String?,
      rideId: (data['rideId'] as String?) ?? '',
      placeName: (data['placeName'] as String?) ?? 'Unknown Location',
      weekId: (data['weekId'] as String?) ?? '',
      motorModelId: (data['motorModelId'] as String?) ?? '',
      motorModelName: (data['motorModelName'] as String?) ?? 'Scooter',
      motorBrand: (data['motorBrand'] as String?) ?? '',
      topSpeedKmh: (data['topSpeedKmh'] as num?)?.toDouble() ?? 0,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class LeaderboardScope {
  const LeaderboardScope({
    required this.placeId,
    required this.placeName,
    required this.weekId,
    required this.motorModel,
  });

  final String placeId;
  final String placeName;
  final String weekId;
  final ScooterModel motorModel;

  String get leaderboardId => '${placeId}_${motorModel.id}_$weekId';
}

class CloudRideService {
  CloudRideService._();

  static final CloudRideService instance = CloudRideService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<LeaderboardScope?> scopeForRide({
    required RideModel ride,
    required ScooterModel motorModel,
  }) async {
    if (ride.routePoints.isEmpty) {
      return null;
    }
    final place = await MapboxService.reverseGeocodePlace(
      ride.routePoints.first,
    );
    final placeName = place?.placeName ?? 'Unknown Location';
    final weekId = _weekIdFor(ride.dateTime);
    return LeaderboardScope(
      placeId: _slug(placeName),
      placeName: placeName,
      weekId: weekId,
      motorModel: motorModel,
    );
  }

  Future<LeaderboardScope> fallbackScopeForLatestRide({
    required RideModel ride,
    required ScooterModel motorModel,
  }) async {
    return await scopeForRide(ride: ride, motorModel: motorModel) ??
        LeaderboardScope(
          placeId: _slug('Unknown Location'),
          placeName: 'Unknown Location',
          weekId: currentWeekId,
          motorModel: motorModel,
        );
  }

  String get currentWeekId => _weekIdFor(DateTime.now());

  Future<LeaderboardScope?> saveRideAndSubmitBestSpeed(RideModel ride) async {
    if (!ride.hasMeaningfulDistance) {
      return null;
    }
    if (!ride.recordForLeaderboard) {
      return null;
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const CloudRideException('Sign in to upload rides online.');
    }
    if (!await isOnline) {
      throw const CloudRideException('Leaderboards are online only.');
    }
    if (ride.vehicleName != RouteVehicle.motorcycle.name) {
      throw const CloudRideException(
        'Motor leaderboards only accept motorcycle rides.',
      );
    }
    final motorModel = await MotorcycleCatalogService.instance.findById(
      ride.motorModelId,
    );
    if (motorModel == null) {
      throw const CloudRideException(
        'Select your scooter model before submitting to leaderboards.',
      );
    }

    final scope = await fallbackScopeForLatestRide(
      ride: ride,
      motorModel: motorModel,
    );
    final topSpeedKmh = ride.maxSpeedMetersPerSecond * 3.6;
    final userRideRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rides')
        .doc(ride.id);
    final leaderboardRef = _firestore
        .collection('leaderboards')
        .doc(scope.leaderboardId);
    final entryRef = leaderboardRef.collection('entries').doc(user.uid);

    await userRideRef.set({
      ...ride.toMap(),
      'userId': user.uid,
      'placeId': scope.placeId,
      'placeName': scope.placeName,
      'weekId': scope.weekId,
      'motorModelId': motorModel.id,
      'motorModelName': motorModel.label,
      'motorBrand': motorModel.brand,
      'motorCc': motorModel.displacementCc,
      'motorDescription': motorModel.description,
      'topSpeedKmh': topSpeedKmh,
      'recordForLeaderboard': true,
      'uploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await leaderboardRef.set({
      'placeId': scope.placeId,
      'placeName': scope.placeName,
      'weekId': scope.weekId,
      'motorModelId': motorModel.id,
      'motorModelName': motorModel.label,
      'motorBrand': motorModel.brand,
      'motorCc': motorModel.displacementCc,
      'motorDescription': motorModel.description,
      'startsAt': Timestamp.fromDate(_weekStartFor(ride.dateTime)),
      'endsAt': Timestamp.fromDate(
        _weekStartFor(ride.dateTime).add(const Duration(days: 7)),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final existingEntry = await entryRef.get();
    final existingTopSpeed =
        (existingEntry.data()?['topSpeedKmh'] as num?)?.toDouble() ?? -1;
    if (!existingEntry.exists || topSpeedKmh > existingTopSpeed) {
      await entryRef.set({
        'userId': user.uid,
        'displayName': user.displayName ?? 'Rydar Rider',
        'photoUrl': user.photoURL,
        'rideId': ride.id,
        'placeId': scope.placeId,
        'placeName': scope.placeName,
        'weekId': scope.weekId,
        'motorModelId': motorModel.id,
        'motorModelName': motorModel.label,
        'motorBrand': motorModel.brand,
        'motorCc': motorModel.displacementCc,
        'motorDescription': motorModel.description,
        'topSpeedKmh': topSpeedKmh,
        'recordForLeaderboard': true,
        'distanceMeters': ride.distanceMeters,
        'durationSeconds': ride.durationSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return scope;
  }

  Stream<List<LeaderboardEntry>> topEntriesForScope(LeaderboardScope scope) {
    return _firestore
        .collection('leaderboards')
        .doc(scope.leaderboardId)
        .collection('entries')
        .orderBy('topSpeedKmh', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaderboardEntry.fromSnapshot(doc))
              .toList(),
        );
  }

  static String _slug(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'unknown-location' : normalized;
  }

  static DateTime _weekStartFor(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.subtract(Duration(days: localDate.weekday - 1));
  }

  static String _weekIdFor(DateTime date) {
    final weekStart = _weekStartFor(date);
    final yearStart = _weekStartFor(DateTime(weekStart.year, 1, 4));
    final weekNumber = (weekStart.difference(yearStart).inDays ~/ 7) + 1;
    return '${weekStart.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}

class CloudRideException implements Exception {
  const CloudRideException(this.message);

  final String message;

  @override
  String toString() => message;
}
