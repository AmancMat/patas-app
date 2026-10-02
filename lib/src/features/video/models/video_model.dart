class VideoModel {
  final String id;
  final String url;
  final String thumbnailUrl;
  final int durationSeconds;
  final DateTime createdAt;

  // Metadados de edição
  final double? startTrim;
  final double? endTrim;
  final int rotation; // 0, 90, 180, 270
  final CropData? cropData;

  VideoModel({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.createdAt,
    this.startTrim,
    this.endTrim,
    this.rotation = 0,
    this.cropData,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      durationSeconds: json['duration_seconds'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      startTrim: json['start_trim']?.toDouble(),
      endTrim: json['end_trim']?.toDouble(),
      rotation: json['rotation'] ?? 0,
      cropData: json['crop_data'] != null
          ? CropData.fromJson(json['crop_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
      'start_trim': startTrim,
      'end_trim': endTrim,
      'rotation': rotation,
      'crop_data': cropData?.toJson(),
    };
  }
}

class CropData {
  final double x;
  final double y;
  final double width;
  final double height;

  CropData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory CropData.fromJson(Map<String, dynamic> json) {
    return CropData(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
