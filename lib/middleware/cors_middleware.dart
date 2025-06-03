import 'dart:io';
import 'package:shelf/shelf.dart';

/// Middleware for handling CORS with specific allowed origins
Middleware corsMiddleware({List<String> allowedOrigins = const []}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'];
      final isAllowed = origin != null && (
        allowedOrigins.contains(origin) || allowedOrigins.contains('*')
      );

      final corsHeaders = {
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Max-Age': '86400',
      };

      if (isAllowed && origin != null) {
        corsHeaders['Access-Control-Allow-Origin'] = origin;
      }

      // Handle preflight
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final response = await innerHandler(request);

      return response.change(
        headers: {
          ...response.headers,
          ...corsHeaders,
          if (isAllowed && origin != null)
            'Access-Control-Allow-Origin': origin,
        },
      );
    };
  };
}
