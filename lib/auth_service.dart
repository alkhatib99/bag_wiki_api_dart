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

  AuthService(this._db, this._jwtSecret, {Duration? tokenExpiration})
      : _tokenExpiration = tokenExpiration ?? const Duration(hours: 24);

  /// Authenticates a user with email and password
  Future<Map<String, dynamic>?> authenticate(String email, String password) async {
    try {
      final results = await _db.query(
        'SELECT id, username, email, "passwordHash", role FROM users_sections WHERE email = @email',
        substitutionValues: {'email': email},
      );

      if (results.isEmpty) {
        return null; // User not found
      }

      final user = {
        'id': results[0][0],
        'username': results[0][1],
        'email': results[0][2],
        'passwordHash': results[0][3],
        'role': results[0][4],
      };

      // Verify password
      final bool isValid = BCrypt.checkpw(password, user['passwordHash'] as String);
      if (!isValid) {
        return null; // Invalid password
      }

      // Generate JWT token
      final token = generateToken(user);

      return {
        'user': {
          'id': user['id'],
          'username': user['username'],
          'email': user['email'],
          'role': user['role'],
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
        'username': user['username'],
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

  /// Creates a new user
  Future<Map<String, dynamic>?> createUser(
    String username,
    String email,
    String password,
    String role,
  ) async {
    try {
      // Hash the password
      final String passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final results = await _db.query(
        '''
        INSERT INTO users_sections (username, email, "passwordHash", role)
        VALUES (@username, @email, @passwordHash, @role)
        RETURNING id, username, email, role, "createdAt"
        ''',
        substitutionValues: {
          'username': username,
          'email': email,
          'passwordHash': passwordHash,
          'role': role,
        },
      );

      if (results.isEmpty) {
        return null;
      }

      return {
        'id': results[0][0],
        'username': results[0][1],
        'email': results[0][2],
        'role': results[0][3],
        'createdAt': results[0][4],
      };
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }
}
