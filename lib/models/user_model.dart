// lib/models/user_model.dart
class User {
  final String id;
  final String email;
  final String restaurantName;
  final String phoneNumber;
  final String profileImage;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.restaurantName,
    required this.phoneNumber,
    required this.profileImage,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final idStr = id != null ? id.toString() : (json['_id']?.toString() ?? '');
    return User(
      id: idStr,
      email: json['email'] ?? '',
      restaurantName: json['restaurantName'] ?? json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      profileImage: json['profile_image'] ?? json['profileImage'] ?? '',
      role: json['role'] ?? 'restaurant_owner',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'restaurantName': restaurantName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? restaurantName,
    String? phoneNumber,
    String? profileImage,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      restaurantName: restaurantName ?? this.restaurantName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
