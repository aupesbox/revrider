// lib/models/user_profile.dart
import 'dart:convert';

class UserProfile {
  final String name;
  final String alias;
  final String email;
  final String phone;
  final bool marketingOptIn;
  final bool googleSignedIn;
  final String? googlePhotoUrl;

  const UserProfile({
    this.name = '',
    this.alias = '',
    this.email = '',
    this.phone = '',
    this.marketingOptIn = true,
    this.googleSignedIn = false,
    this.googlePhotoUrl,
  });

  UserProfile copyWith({
    String? name,
    String? alias,
    String? email,
    String? phone,
    bool? marketingOptIn,
    bool? googleSignedIn,
    String? googlePhotoUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      alias: alias ?? this.alias,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      googleSignedIn: googleSignedIn ?? this.googleSignedIn,
      googlePhotoUrl: googlePhotoUrl ?? this.googlePhotoUrl,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'alias': alias,
    'email': email,
    'phone': phone,
    'marketingOptIn': marketingOptIn,
    'googleSignedIn': googleSignedIn,
    'googlePhotoUrl': googlePhotoUrl,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    name: (m['name'] ?? '') as String,
    alias: (m['alias'] ?? '') as String,
    email: (m['email'] ?? '') as String,
    phone: (m['phone'] ?? '') as String,
    marketingOptIn: (m['marketingOptIn'] ?? true) as bool,
    googleSignedIn: (m['googleSignedIn'] ?? false) as bool,
    googlePhotoUrl: m['googlePhotoUrl'] as String?,
  );

  String toJson() => jsonEncode(toMap());
  factory UserProfile.fromJson(String s) => UserProfile.fromMap(jsonDecode(s) as Map<String, dynamic>);
}
