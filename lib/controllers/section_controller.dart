import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../models/section_model.dart';
import 'package:postgres/postgres.dart';

class SectionController {
  final PostgreSQLConnection _db;
  Router get router => _router;
  final _router = Router();

  SectionController(this._db) {
    _router.get('/', _getAllSections);
    _router.get('/<id>', _getSectionById);
    _router.post('/', _createSection);
    _router.put('/<id>', _updateSection);
    _router.delete('/<id>', _deleteSection);
  }

  Future<Response> _getAllSections(Request request) async {
    try {
      final results = await _db.query('SELECT * FROM sections ORDER BY id');
      
      final sections = results.map((row) {
        return Section(
          id: row[0] as int,
          title: row[1] as String,
          content: row[2] as String,
          imageUrl: row[3] as String,
          createdAt: row[4] != null ? DateTime.parse(row[4].toString()) : null,
          updatedAt: row[5] != null ? DateTime.parse(row[5].toString()) : null,
        ).toJson();
      }).toList();
      
      return Response.ok(
        json.encode(sections),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error fetching sections: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch sections: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getSectionById(Request request, String id) async {
    try {
      final sectionId = int.tryParse(id);
      if (sectionId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid section ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final results = await _db.query(
        'SELECT * FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );

      if (results.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Section not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final row = results.first;
      final section = Section(
        id: row[0] as int,
        title: row[1] as String,
        content: row[2] as String,
        imageUrl: row[3] as String,
        createdAt: row[4] != null ? DateTime.parse(row[4].toString()) : null,
        updatedAt: row[5] != null ? DateTime.parse(row[5].toString()) : null,
      ).toJson();

      return Response.ok(
        json.encode(section),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch section: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createSection(Request request) async {
    try {
      final jsonBody = await request.readAsString();
      final Map<String, dynamic> data = json.decode(jsonBody);
      
      if (!data.containsKey('title') || !data.containsKey('content') || !data.containsKey('imageUrl')) {
        return Response.badRequest(
          body: json.encode({'error': 'Missing required fields: title, content, or imageUrl'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final title = data['title'] as String;
      final content = data['content'] as String;
      final imageUrl = data['imageUrl'] as String;

      final results = await _db.query(
        '''
        INSERT INTO sections (title, content, "imageUrl")
        VALUES (@title, @content, @imageUrl)
        RETURNING *
        ''',
        substitutionValues: {
          'title': title,
          'content': content,
          'imageUrl': imageUrl,
        },
      );

      final row = results.first;
      final section = Section(
        id: row[0] as int,
        title: row[1] as String,
        content: row[2] as String,
        imageUrl: row[3] as String,
        createdAt: row[4] != null ? DateTime.parse(row[4].toString()) : null,
        updatedAt: row[5] != null ? DateTime.parse(row[5].toString()) : null,
      ).toJson();

      return Response(
        201,
        body: json.encode(section),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create section: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateSection(Request request, String id) async {
    try {
      final sectionId = int.tryParse(id);
      if (sectionId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid section ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final jsonBody = await request.readAsString();
      final Map<String, dynamic> data = json.decode(jsonBody);

      // Check if section exists
      final checkResults = await _db.query(
        'SELECT id FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );

      if (checkResults.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Section not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Build update query dynamically based on provided fields
      final updates = <String>[];
      final values = <String, dynamic>{'id': sectionId};

      if (data.containsKey('title')) {
        updates.add('title = @title');
        values['title'] = data['title'];
      }

      if (data.containsKey('content')) {
        updates.add('content = @content');
        values['content'] = data['content'];
      }

      if (data.containsKey('imageUrl')) {
        updates.add('"imageUrl" = @imageUrl');
        values['imageUrl'] = data['imageUrl'];
      }

      // Add updatedAt timestamp
      updates.add('"updatedAt" = CURRENT_TIMESTAMP');

      if (updates.isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'No fields to update'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final updateQuery = '''
      UPDATE sections
      SET ${updates.join(', ')}
      WHERE id = @id
      RETURNING *
      ''';

      final results = await _db.query(updateQuery, substitutionValues: values);
      final row = results.first;
      final section = Section(
        id: row[0] as int,
        title: row[1] as String,
        content: row[2] as String,
        imageUrl: row[3] as String,
        createdAt: row[4] != null ? DateTime.parse(row[4].toString()) : null,
        updatedAt: row[5] != null ? DateTime.parse(row[5].toString()) : null,
      ).toJson();

      return Response.ok(
        json.encode(section),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to update section: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteSection(Request request, String id) async {
    try {
      final sectionId = int.tryParse(id);
      if (sectionId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid section ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if section exists
      final checkResults = await _db.query(
        'SELECT id FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );

      if (checkResults.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Section not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Delete the section
      await _db.execute(
        'DELETE FROM sections WHERE id = @id',
        substitutionValues: {'id': sectionId},
      );

      return Response(204);
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to delete section: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
