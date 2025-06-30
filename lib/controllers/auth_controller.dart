import 'dart:convert';
import 'package:bag_wiki_api_dart/auth_service.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AuthController {
  final AuthService _authService;
  Router get router => _router;
  final _router = Router();

  AuthController(this._authService) {
    _router.post('/login', _login);
    // Registration disabled for static admin setup
    // _router.post('/register', _register);
  }

  Future<Response> _login(Request request) async {
    try {
      final jsonBody = await request.readAsString();
      final Map<String, dynamic> data = json.decode(jsonBody);

      if (!data.containsKey('email') || !data.containsKey('password')) {
        return Response.badRequest(
          body: json.encode({'error': 'Email and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final email = data['email'] as String;
      final password = data['password'] as String;

      var result = await _authService.authenticate(email, password);

      if (result == null) {
        return Response.unauthorized(
          json.encode({
            'error': 'Invalid admin credentials'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        json.encode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Login failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Registration method disabled for static admin setup
  /*
  Future<Response> _register(Request request) async {
    return Response.badRequest(
      body: json.encode({'error': 'User registration is disabled. Only admin login is supported.'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  */
}

