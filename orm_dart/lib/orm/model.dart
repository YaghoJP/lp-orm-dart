import 'dart:mirrors';
import '../database.dart';
import 'annotations.dart';
import 'query_builder.dart';

abstract class Model {
  Future<void> save() async {
    final conn = Database.connection;
    final mirror = reflect(this);
    final classMirror = mirror.type;

    final tableAnn = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;

    final columns = <String>[];
    final values = <String>[];
    final substitutions = <String, dynamic>{};
    String? primaryKeyName;
    dynamic primaryKeyValue;

    for (var decl in classMirror.declarations.values) {
      if (decl is VariableMirror && decl.metadata.isNotEmpty) {
        final colAnn = decl.metadata
            .firstWhere((m) => m.reflectee is Column)
            .reflectee as Column;

        final name = MirrorSystem.getName(decl.simpleName);
        final value = mirror.getField(decl.simpleName).reflectee;

        if (colAnn.primaryKey) {
          primaryKeyName = colAnn.name;
          primaryKeyValue = value;
          continue; // pula do insert/update
        }

        columns.add(colAnn.name);
        values.add('@$name');
        substitutions[name] = value;
      }
    }

    if (primaryKeyValue == null) {
      // INSERT
      final result = await conn.query(
        'INSERT INTO ${tableAnn.name} (${columns.join(', ')}) VALUES (${values.join(', ')}) RETURNING $primaryKeyName',
        substitutionValues: substitutions,
      );
      if (primaryKeyName != null) {
        mirror.setField(Symbol(primaryKeyName!), result.first[0]);
      }
    } else {
      // UPDATE
      final sets = <String>[];
      for (var i = 0; i < columns.length; i++) {
        sets.add('${columns[i]} = ${values[i]}');
      }
      substitutions['id'] = primaryKeyValue;

      await conn.query(
        'UPDATE ${tableAnn.name} SET ${sets.join(', ')} WHERE $primaryKeyName = @id',
        substitutionValues: substitutions,
      );
    }
  }

  Future<void> delete() async {
    final conn = Database.connection;
    final mirror = reflect(this);
    final classMirror = mirror.type;

    final tableAnn = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;

    String? primaryKeyName;
    dynamic primaryKeyValue;

    for (var decl in classMirror.declarations.values) {
      if (decl is VariableMirror && decl.metadata.isNotEmpty) {
        final colAnn = decl.metadata
            .firstWhere((m) => m.reflectee is Column)
            .reflectee as Column;
        if (colAnn.primaryKey) {
          primaryKeyName = colAnn.name;
          primaryKeyValue =
              mirror.getField(decl.simpleName).reflectee;
          break;
        }
      }
    }

    if (primaryKeyName == null || primaryKeyValue == null) {
      throw Exception('Chave primária não definida.');
    }

    await conn.query(
      'DELETE FROM ${tableAnn.name} WHERE $primaryKeyName = @id',
      substitutionValues: {'id': primaryKeyValue},
    );
  }

  static Future<T?> findById<T extends Model>(int id, T Function() builder) async {
    final instance = builder();
    final mirror = reflect(instance);
    final classMirror = mirror.type;

    final tableAnn = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;

    String? primaryKeyName;
    final columns = <String, String>{}; // map campo => nome coluna

    for (var decl in classMirror.declarations.values) {
      if (decl is VariableMirror && decl.metadata.isNotEmpty) {
        final colAnn = decl.metadata
            .firstWhere((m) => m.reflectee is Column)
            .reflectee as Column;

        final fieldName = MirrorSystem.getName(decl.simpleName);
        columns[fieldName] = colAnn.name;

        if (colAnn.primaryKey) {
          primaryKeyName = colAnn.name;
        }
      }
    }

    if (primaryKeyName == null) {
      throw Exception('Chave primária não definida.');
    }

    final conn = Database.connection;
    final result = await conn.query(
      'SELECT ${columns.values.join(', ')} FROM ${tableAnn.name} WHERE $primaryKeyName = @id',
      substitutionValues: {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final instanceMirror = reflect(instance);
    int i = 0;
    for (final field in columns.keys) {
      instanceMirror.setField(Symbol(field), row[i++]);
    }

    return instance as T;
  }

  static Future<List<T>> all<T extends Model>(T Function() builder) async {
    final instance = builder();
    final mirror = reflect(instance);
    final classMirror = mirror.type;

    final tableAnn = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;

    final columns = <String, String>{}; // campo -> nome coluna

    for (var decl in classMirror.declarations.values) {
      if (decl is VariableMirror && decl.metadata.isNotEmpty) {
        final colAnn = decl.metadata
            .firstWhere((m) => m.reflectee is Column)
            .reflectee as Column;

        final fieldName = MirrorSystem.getName(decl.simpleName);
        columns[fieldName] = colAnn.name;
      }
    }

    final conn = Database.connection;
    final result = await conn.query('SELECT ${columns.values.join(', ')} FROM ${tableAnn.name}');

    final items = <T>[];
    for (var row in result) {
      final item = builder();
      final itemMirror = reflect(item);
      int i = 0;
      for (final field in columns.keys) {
        itemMirror.setField(Symbol(field), row[i++]);
      }
      items.add(item);
    }

    return items;
  }

  static Future<List<T>> query<T extends Model>(
    String sql, {
    required T Function() builder,
    Map<String, dynamic>? substitutionValues,
  }) async {
    final results = await Database.connection.query(
      sql,
      substitutionValues: substitutionValues,
    );

    return results.map((row) {
      final instance = builder();
      final mirror = reflect(instance);
      final classMirror = mirror.type;

      final fields = <String, Symbol>{};

      for (var decl in classMirror.declarations.values) {
        if (decl is VariableMirror && decl.metadata.isNotEmpty) {
          final colAnn = decl.metadata
              .firstWhere((m) => m.reflectee.runtimeType.toString() == 'Column')
              .reflectee;

          fields[(colAnn as dynamic).name] = decl.simpleName;
        }
      }

      for (var i = 0; i < row.length; i++) {
        final columnName = results.columnDescriptions[i].columnName;
        final symbol = fields[columnName];
        if (symbol != null) {
          mirror.setField(symbol, row[i]);
        }
      }

      return instance;
    }).toList();
  }

  static QueryBuilder<T> queryBuilder<T extends Model>(T Function() builder) {
    return QueryBuilder<T>(builder);
  }

}
