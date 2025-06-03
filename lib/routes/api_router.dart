import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'middleware/cors_middleware.dart';
import 'controllers/section_controller.dart';

/// API router configuration
class ApiRouter {
  final Router _router = Router();
  
  /// Constructor
  ApiRouter(sectionController) {
    // Load environment variables
    final env = DotEnv(includePlatformEnvironment: true)..load();
    
    // Configure allowed origins for CORS
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
    
    // Mount section routes
    _router.mount('/api/sections', Pipeline()
        .addMiddleware(corsMiddleware(allowedOrigins: allowedOrigins))
        .addHandler(sectionController.router));
    
    // Root route
    _router.get('/', (Request request) {
      return Response.ok(
        '{"message": "Welcome to BAG Wiki API", "version": "1.0.0"}',
        headers: {'Content-Type': 'application/json'},
      );
    });
  }
  
  /// Get the configured router
  Router get router => _router;
}
