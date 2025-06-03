import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../models/section_model.dart';

/// Controller for handling section-related API endpoints
class SectionController {
  final PostgreSQLConnection _db;
  
  /// Constructor
  SectionController(this._db);
  
  /// Create a router with all section endpoints
  Router get router {
    final router = Router();
    
    // GET /api/sections - Get all sections
    router.get('/', _getAllSections);
    
    // GET /api/sections/:id - Get a specific section
    router.get('/<id>', _getSectionById);
    
    // POST /api/sections - Create a new section
    router.post('/', _createSection);
    
    // PUT /api/sections/:id - Update a section
    router.put('/<id>', _updateSection);
    
    // DELETE /api/sections/:id - Delete a section
    router.delete('/<id>', _deleteSection);
    
    return router;
  }
  
  /// Get all sections
  Future<Response> _getAllSections(Request request) async {
    try {
      final results = await _db.query('SELECT * FROM sections ORDER BY id');
      final sections = results.map((row) {
        return Section.fromDatabase(row.toColumnMap()).toJson();
      }).toList();
      
      return Response.ok(
        jsonEncode(sections),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error getting all sections: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch sections'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  /// Get a section by ID
  Future<Response> _getSectionById(Request request, String id) async {
    try {
      final sectionId = int.tryParse(id);
      if (sectionId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid section ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final results = await _db.query(
        'SELECT * FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );
      
      if (results.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Section not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final section = Section.fromDatabase(results.first.toColumnMap()).toJson();
      
      return Response.ok(
        jsonEncode(section),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error getting section by ID: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch section'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  /// Create a new section
  Future<Response> _createSection(Request request) async {
    try {
      final jsonBody = await request.readAsString();
      final Map<String, dynamic> body = jsonDecode(jsonBody);
      
      // Validate required fields
      if (body['title'] == null || body['content'] == null || body['imageUrl'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Title, content, and imageUrl are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final section = Section(
        title: body['title'],
        content: body['content'],
        imageUrl: body['imageUrl'],
      );
      
      final result = await _db.query(
        '''
        INSERT INTO sections (title, content, "imageUrl")
        VALUES (@title, @content, @imageUrl)
        RETURNING *
        ''',
        substitutionValues: section.toDatabase(),
      );
      
      final createdSection = Section.fromDatabase(result.first.toColumnMap()).toJson();
      
      return Response(
        201,
        body: jsonEncode(createdSection),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error creating section: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create section'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  /// Update a section
  Future<Response> _updateSection(Request request, String id) async {
    try {
      final sectionId = int.tryParse(id);
      if (sectionId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid section ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Check if section exists
      final checkResult = await _db.query(
        'SELECT id FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );
      
      if (checkResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Section not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final jsonBody = await request.readAsString();
      final Map<String, dynamic> body = jsonDecode(jsonBody);
      
      // Validate required fields
      if (body['title'] == null || body['content'] == null || body['imageUrl'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Title, content, and imageUrl are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final section = Section(
        id: sectionId,
        title: body['title'],
        content: body['content'],
        imageUrl: body['imageUrl'],
      );
      
      final result = await _db.query(
        '''
        UPDATE sections
        SET title = @title, content = @content, "imageUrl" = @imageUrl, "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        substitutionValues: section.toDatabase(),
      );
      
      final updatedSection = Section.fromDatabase(result.first.toColumnMap()).toJson();
      
      return Response.ok(
        jsonEncode(updatedSection),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error updating section: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update section'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  /// Delete a section
  Future<Response> _deleteSection(Request request, String id) async {
    try {
      final sectionId = int.tryParse(id);
      if (sectionId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid section ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Check if section exists
      final checkResult = await _db.query(
        'SELECT id FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );
      
      if (checkResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Section not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      await _db.query(
        'DELETE FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );
      
      return Response(204);
    } catch (e) {
      print('Error deleting section: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete section'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
