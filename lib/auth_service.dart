// ignore_for_file: dead_code_on_catch_subtype

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  final PostgreSQLConnection _db;
  final String _jwtSecret;
  final Duration _tokenExpiration;
  final String? _adminEmail;
  final String? _adminPassword;

  AuthService(this._db, this._jwtSecret, {Duration? tokenExpiration})
      : _tokenExpiration = tokenExpiration ?? const Duration(hours: 24),
        _adminEmail = Platform.environment['ADMIN_EMAIL'],
        _adminPassword = Platform.environment['ADMIN_PASSWORD'] {
    // Log warning if admin credentials are missing
    if (_adminEmail == null || _adminPassword == null) {
      print('WARNING: ADMIN_EMAIL or ADMIN_PASSWORD not found in environment variables');
      print('Please ensure .env file contains ADMIN_EMAIL and ADMIN_PASSWORD');
    }
  }

  /// Authenticates a user with email and password using static admin credentials
  Future<Map<String, dynamic>?> authenticate(
      String email, String password) async {
    try {
      print('Authenticating user with email: $email');
      
      // Check if admin credentials are configured
      if (_adminEmail == null || _adminPassword == null) {
        print('Admin credentials not configured in environment variables');
        return null;
      }

      // Validate against static admin credentials
      if (email != _adminEmail || password != _adminPassword) {
        print('Invalid admin credentials provided');
        return null;
      }

      // Create admin user object
      final adminUser = {
        'id': 1, // Static admin ID
        'email': _adminEmail,
        'role': 'admin',
      };

      // Generate JWT token
      final token = generateToken(adminUser);

      return {
        'user': {
          'id': adminUser['id'],
          'email': adminUser['email'],
          'role': adminUser['role'],
        },
        'token': token,
      };
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  /// Generates a JWT token for the user
  String generateToken(Map<String, dynamic> user) {
    final jwt = JWT(
      {
        'id': user['id'],
        'email': user['email'],
        'role': user['role'],
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      issuer: 'bag_wiki_api',
    );

    return jwt.sign(
      SecretKey(_jwtSecret),
      expiresIn: _tokenExpiration,
    );
  }

  /// Verifies a JWT token
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      print('JWT expired');
      return null;
    }
  }

  /// Creates a new user - Disabled for static admin setup
  /// This method is kept for backward compatibility but will not create users
  Future<Map<String, dynamic>?> createUser(
    String username,
    String email,
    String password,
    String role,
  ) async {
    print('User registration is disabled. Only static admin login is supported.');
    return null;
  }
}

