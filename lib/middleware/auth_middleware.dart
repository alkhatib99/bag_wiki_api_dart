import 'dart:convert';
import 'package:bag_wiki_api_dart/auth_service.dart';
import 'package:shelf/shelf.dart';
 
/// Middleware to verify JWT token and add user info to request context
Middleware authMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Check for Authorization header
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          json.encode({'error': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Extract token
      final token = authHeader.substring(7);
      final payload = authService.verifyToken(token);
      
      if (payload == null) {
        return Response.unauthorized(
          json.encode({'error': 'Invalid or expired token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add user info to request context
      final updatedRequest = request.change(context: {
        'user': payload,
      });

      // Continue to the inner handler
      return innerHandler(updatedRequest);
    };
  };
}

/// Middleware to check if user has required role
Middleware roleMiddleware(List<String> allowedRoles) {
  return (Handler innerHandler) {
    return (Request request) async {
      final user = request.context['user'] as Map<String, dynamic>?;
      
      if (user == null) {
        return Response.unauthorized(
          json.encode({'error': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userRole = user['role'] as String;
      
      if (!allowedRoles.contains(userRole)) {
        return Response.forbidden(
          json.encode({'error': 'Insufficient permissions'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // User has required role, continue to inner handler
      return innerHandler(request);
    };
  };
}
