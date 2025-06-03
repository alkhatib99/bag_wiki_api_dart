import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

/// Database configuration class for PostgreSQL connection
class DatabaseConfig {
  late final String host;
  late final int port;
  late final String database;
  late final String username;
  late final String password;
  late final bool useSSL;
  
  /// Singleton instance
  static final DatabaseConfig _instance = DatabaseConfig._internal();
  
  /// Factory constructor to return the singleton instance
  factory DatabaseConfig() {
    return _instance;
  }
  
  /// Private constructor for singleton pattern
  DatabaseConfig._internal() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    
    host = env['DB_HOST'] ?? 'localhost';
    port = int.parse(env['DB_PORT'] ?? '5432');
    database = env['DB_NAME'] ?? 'postgres';
    username = env['DB_USER'] ?? 'postgres';
    password = env['DB_PASSWORD'] ?? 'postgres';
    useSSL = env['DB_SSL']?.toLowerCase() == 'true';
  }
  
  /// Create a PostgreSQL connection
  Future<PostgreSQLConnection> createConnection() async {
    final connection = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
      useSSL: useSSL,
    );
    
    try {
      await connection.open();
      print('Database connection established successfully');
      return connection;
    } catch (e) {
      print('Failed to connect to the database: $e');
      rethrow;
    }
  }
  
  /// Test the database connection
  Future<bool> testConnection() async {
    PostgreSQLConnection? connection;
    
    try {
      connection = await createConnection();
      await connection.query('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    } finally {
      await connection?.close();
    }
  }
  
  /// Initialize the database schema
  Future<void> initializeDatabase(PostgreSQLConnection connection) async {
    try {
      // Create sections table if it doesn't exist
      await connection.query('''
        CREATE TABLE IF NOT EXISTS sections (
          id SERIAL PRIMARY KEY,
          title VARCHAR(255) NOT NULL,
          content TEXT NOT NULL,
          "imageUrl" VARCHAR(255) NOT NULL,
          "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      print('Database schema initialized successfully');
    } catch (e) {
      print('Failed to initialize database schema: $e');
      rethrow;
    }
  }
}
