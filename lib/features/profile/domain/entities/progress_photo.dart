class ProgressPhoto {
  final String id;
  final String userId;
  final String filePath;
  final String signedUrl;
  final DateTime createdAt;
  final String pose;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.filePath,
    required this.signedUrl,
    required this.createdAt,
    this.pose = 'Front',
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      filePath: json['file_path'] as String,
      signedUrl: json['signed_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      pose: json['pose'] as String? ?? 'Front',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
      'pose': pose,
    };
  }
}
