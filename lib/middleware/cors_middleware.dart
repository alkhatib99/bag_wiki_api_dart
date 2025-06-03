import 'dart:io';
import 'package:shelf/shelf.dart';

/// Middleware for handling CORS with specific allowed origins
Middleware corsMiddleware({List<String> allowedOrigins = const []}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Get the origin from the request headers
      final origin = request.headers['origin'];
      
      // Check if the origin is allowed
      final isAllowed = origin != null && (
        allowedOrigins.contains(origin) || 
        allowedOrigins.contains('*')
      );
      
      // Handle preflight OPTIONS request
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': isAllowed ? origin : '',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Max-Age': '86400', // 24 hours
        });
      }
      
      // Handle the actual request
      final response = await innerHandler(request);
      
      // Add CORS headers to the response
      return response.change(headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': isAllowed ? origin : '',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
        'Access-Control-Allow-Credentials': 'true',
      });
    };
  };
}
