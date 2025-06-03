import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    'gamesfra3.bisecthosting.com',
    5432,
    's293297_test',
    username: 'u293297_Be11RGKyDP',
    password: '9qijZb1BEIDppU7ivJuNxLoa',
    useSSL: true,
    allowClearTextPassword: true,
  );

  try {
    await connection.open();
    print('Connected successfully!');

    var results = await connection.query('SELECT COUNT(*) FROM sections');
    print('Number of sections: ${results[0][0]}');

    await connection.close();
  } catch (e) {
    print('Connection failed: $e');
    exit(1);
  }
}
