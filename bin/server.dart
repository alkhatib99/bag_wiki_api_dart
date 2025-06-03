import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';
import 'package:args/args.dart';

import 'config/database_config.dart';
import 'controllers/section_controller.dart';

// Configure routes
Router _configureRouter(DatabaseConfig dbConfig) {
  final router = Router();
  
  // Create database connection
  final dbConnection = dbConfig.createConnection();
  
  // Set up section routes
  dbConnection.then((connection) {
    final sectionController = SectionController(connection);
    router.mount('/api/sections', sectionController.router);
  });
  
  // Root route
  router.get('/', (Request request) {
    return Response.ok(
      '{"message": "Welcome to BAG Wiki API"}',
      headers: {'Content-Type': 'application/json'},
    );
  });
  
  return router;
}

void main(List<String> args) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsValue: '8080');
  
  final result = parser.parse(args);
  final port = int.parse(result['port'] as String);
  
  // Load environment variables
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  // Initialize database configuration
  final dbConfig = DatabaseConfig();
  final isConnected = await dbConfig.testConnection();
  
  if (!isConnected) {
    stderr.writeln('Failed to connect to the database. Exiting...');
    exit(1);
  }
  
  // Create a connection and initialize the database
  final connection = await dbConfig.createConnection();
  await dbConfig.initializeDatabase(connection);
  
  // Configure CORS
  final allowedOrigins = [
    'https://bag-wiki.vercel.app',
    'https://bag-wiki-admin.vercel.app',
  ];
  
  // Add localhost for development
  if (env['ENVIRONMENT'] == 'development') {
    allowedOrigins.addAll([
      'http://localhost:3000',
      'http://localhost:8080',
      'http://localhost:5000',
    ]);
  }
  
  final corsHeaders = {
    'Access-Control-Allow-Origin': allowedOrigins.join(','),
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    'Access-Control-Allow-Credentials': 'true',
  };
  
  // Configure middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(_configureRouter(dbConfig));
  
  // Start server
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}
