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
import 'package:postgres/postgres.dart';

// Configure routes
Future<Router> configureRouter(
    PostgreSQLConnection connection, AuthService authService) async {
  final router = Router();

  // Set up auth routes (unprotected)
  final authController = AuthController(authService);
  router.mount('/auth', authController.router);

  // Set up section controller
  final sectionController = SectionController(connection);

  // Public section routes (no authentication required)
  router.get('/api/sections', sectionController.getAllSectionsHandler);
  router.get('/api/sections/<id>', sectionController.getSectionByIdHandler);

  // Authenticated section routes (authentication required)
  final authenticatedSectionRouter = Router();
  authenticatedSectionRouter.post(
      '/create', sectionController.createSectionHandler);
  authenticatedSectionRouter.put(
      '/<id>/update', sectionController.updateSectionHandler);
  authenticatedSectionRouter.delete(
      '/<id>', sectionController.deleteSectionHandler);

  // Apply authentication middleware to the authenticated section routes
  router.mount(
    '/api/sections',
    Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(authenticatedSectionRouter),
  );

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

  // Create a single, persistent database connection
  final connection = await dbConfig.createConnection();

  // Test the connection using the persistent connection
  final isConnected = await dbConfig.testConnection(connection);

  if (!isConnected) {
    stderr.writeln('Failed to connect to the database. Exiting...');
    await connection.close(); // Ensure connection is closed on failure
    exit(1);
  }

  // Initialize the database schema using the persistent connection
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
  // Pass the persistent connection to configureRouter
  final router = await configureRouter(connection, authService);

  // Configure middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: corsHeadersMap))
      .addHandler(router);

  // Start server
  final server = await serve(handler, InternetAddress.anyIPv4, port);

  // Print server information
  print('Server started on http://${server.address.host}:${server.port}');
  print('Server listening on port ${server.port}');
  print('Database connection established successfully.');
  print('Auth service initialized with JWT secret: $jwtSecret');

  env.load();
  final fields = env['FIELDS']?.split(',') ?? [];

  print('Fields:');
  if (fields.isEmpty) {
    print('No fields specified in environment variables.');
  } else {
    print('Fields from environment variables:');
  }

  // Print registered routes for debugging
  print('Registered routes:');
  // router.all('/<ignored|.*>', (Request request) {
  //   return Response.notFound('Not Found');
  // });

  print('Root route registered at /');
  print('Auth routes registered at /auth/login');
  print('Auth routes registered at /auth/register');
  print('Section routes registered at /api/sections');
  print('Section routes registered at /api/sections/<id>');
  print('Section routes registered at /api/sections/<id>/create');
  print('Section routes registered at /api/sections/<id>/update');
  print('Section routes registered under /api/sections');

  // Add a shutdown hook to close the database connection gracefully
  ProcessSignal.sigint.watch().listen((signal) async {
    print(
        '\nReceived SIGINT. Shutting down server and closing database connection...');
    await server.close(force: true);
    await connection.close();
    print('Server stopped and database connection closed.');
    exit(0);
  });
}
