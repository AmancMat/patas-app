import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class FriendlyPlace {
  final String id;
  final String? userId;
  final String name;
  final String category;
  final String? description;
  final String address;
  final String? phone;
  final double latitude;
  final double longitude;
  final String? rulesDescription;
  final List<String> photoUrls;
  final List<dynamic>? boundaryPolygon;
  final bool isActive;
  final bool isClaimed;
  final String? claimedBy;
  final String? creatorName;
  final String? creatorPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendlyPlace({
    required this.id,
    this.userId,
    required this.name,
    required this.category,
    this.description,
    required this.address,
    this.phone,
    required this.latitude,
    required this.longitude,
    this.rulesDescription,
    required this.photoUrls,
    this.boundaryPolygon,
    required this.isActive,
    required this.isClaimed,
    this.claimedBy,
    this.creatorName,
    this.creatorPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendlyPlace.fromJson(Map<String, dynamic> json) {
    final tutor = json['tutor_profiles'];
    final creatorName = tutor is Map ? tutor['name'] as String? : null;
    final creatorPhotoUrl = tutor is Map ? tutor['photo_url'] as String? : null;

    return FriendlyPlace(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rulesDescription: json['rules_description'],
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'])
          : [],
      boundaryPolygon: json['boundary_polygon'],
      isActive: json['is_active'] ?? true,
      isClaimed: json['is_claimed'] ?? false,
      claimedBy: json['claimed_by'],
      creatorName: creatorName,
      creatorPhotoUrl: creatorPhotoUrl,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'rules_description': rulesDescription,
      'photo_urls': photoUrls,
      'boundary_polygon': boundaryPolygon,
      'is_active': isActive,
      'is_claimed': isClaimed,
      'claimed_by': claimedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  List<LatLng> getPolygonPoints() {
    if (boundaryPolygon == null) return [];
    try {
      dynamic data = boundaryPolygon;
      if (data is List && data.isNotEmpty && data.first is List) {
        final inner = data.first;
        if (inner is List && inner.isNotEmpty && inner.first is List) {
          data = inner;
        }
      }
      if (data is List) {
        final List<LatLng> points = [];
        for (var item in data) {
          if (item is Map) {
            final lat = (item['lat'] ?? item['latitude'] as num).toDouble();
            final lng = (item['lng'] ?? item['longitude'] as num).toDouble();
            points.add(LatLng(lat, lng));
          } else if (item is List && item.length >= 2) {
            final lng = (item[0] as num).toDouble();
            final lat = (item[1] as num).toDouble();
            points.add(LatLng(lat, lng));
          }
        }
        return points;
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing getPolygonPoints: $e');
      return [];
    }
  }
}
