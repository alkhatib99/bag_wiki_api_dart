import 'dart:io';
import 'package:bag_wiki_api_dart/auth_service.dart';
import 'package:bag_wiki_api_dart/config/database_config.dart';
import 'package:bag_wiki_api_dart/controllers/auth_controller.dart';
import 'package:bag_wiki_api_dart/controllers/section_controller.dart';
import 'package:bag_wiki_api_dart/middleware/auth_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';
import 'package:args/args.dart';

// Configure routes
Future<Router> configureRouter(
    DatabaseConfig dbConfig, AuthService authService) async {
  final router = Router();

  // Create database connection synchronously before registering routes
  final connection = await dbConfig.createConnection();

  // Set up auth routes (unprotected) - SYNCHRONOUSLY
  final authController = AuthController(authService);
  router.mount('/auth', authController.router);

  // Set up section routes (protected) - SYNCHRONOUSLY
  final sectionController = SectionController(connection);

  // Create a pipeline for section routes with authentication and role middleware
  final sectionPipeline = Pipeline()
      .addMiddleware(authMiddleware(authService)); // Apply JWT auth first
  // Role middleware will be applied per-route group if needed, or handled within controller if simpler

  // Mount the section controller's router under /api/sections
  // Apply the authentication middleware to all routes mounted here
  router.mount(
      '/api/sections', sectionPipeline.addHandler(sectionController.router));

  // --- IMPORTANT: Role-based access needs to be handled correctly ---
  // Option 1 (Middleware per route group - more complex with shelf_router mount):
  // You might need a custom mounting solution or apply middleware inside the SectionController router definition.

  // Option 2 (Check roles within SectionController handlers - simpler for now):
  // Modify SectionController handlers (create, update, delete) to check request context for 'admin' role.
  // The authMiddleware should add user info (including role) to request.context.

  // Root route
  router.get('/', (Request request) {
    return Response.ok(
      '{"message": "Welcome to BAG Wiki API", "version": "1.0.0"}',
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}

void main(List<String> args) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption(
      'port',
      abbr: 'p',
    );

  final result = parser.parse(args);
  final port = int.parse(result['port'] as String? ?? '5432') ?? 5432;

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

  // Initialize auth service
  final jwtSecret = env['JWT_SECRET'] ?? 'your-secret-key-change-in-production';
  final authService = AuthService(
    connection,
    jwtSecret,
    tokenExpiration: Duration(hours: 24),
  );

  // Configure CORS with wildcard for testing
  final corsHeadersMap = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers':
        'Origin, Content-Type, Accept, Authorization',
    'Access-Control-Allow-Credentials': 'true',
  };

  // Configure router with await to ensure all routes are registered
  final router = await configureRouter(dbConfig, authService);

  // Configure middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      // Corrected CORS middleware usage
      .addMiddleware(corsHeaders(headers: corsHeadersMap))
      .addHandler(router);

  // Start server
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  
  // Print server information
  print('Server started on http://${server.address.host}:${server.port}');
  // Print server port for debugging
  print('Server listening on port ${server.port}');
  // print('Database connected: ${dbConfig.isConnected}');
  print('Database connection established successfully.');
  // Print auth service initialization
  print('Auth service initialized with JWT secret: $jwtSecret');
  // Print database connection details
  // print('Database connection details: ${dbConfig.connectionDetails}');
  // /print('Database connection string: ${dbConfig.connectionString}');

  // Print environment variables for debugging
  // print('Environment variables:');
  env.load();
  final fields = env['FIELDS']?.split(',') ?? [];
  
  // Print each field
  print('Fields:');
  if (fields.isEmpty) {
    print('No fields specified in environment variables.');
  }
   else {
    print('Fields from environment variables:');
  }
  
  
  // Print registered routes for debugging
  print('Registered routes:');
  router.all('/<ignored|.*>', (Request request) {
    return Response.notFound('Not Found');
  });

  print('Root route registered at /');
  print('Auth routes registered at /auth/login');
  print('Auth routes registered at /auth/register');
  print('Section routes registered at /api/sections');
  print('Section routes registered at /api/sections/<id>');
  print('Section routes registered at /api/sections/<id>/create');
  print('Section routes registered at /api/sections/<id>/update');
  
  // print('Auth routes registered at /auth');
  // print(router)  
  // print routes are registered under server
  // print("")
  print('Section routes registered under /api/sections');
}
