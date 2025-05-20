import 'package:postgres/postgres.dart';

class Database {
  static final _connection = PostgreSQLConnection(
    'localhost',
    5432,
    'dart_orm',
    username: 'postgres',
    password: 'postgres',
  );

  static Future<void> connect() async {
    await _connection.open();
    print('Conectado ao PostgreSQL');
  }

  static PostgreSQLConnection get connection => _connection;
}

