import 'dart:mirrors';
import 'annotations.dart';
import '../database.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'model.dart';
import 'query_builder.dart';

class Orm {

  static ClassMirror getClassMirror(String className){
    final libraryMirror = currentMirrorSystem().libraries.values.firstWhere(
      (lib) => lib.declarations.containsKey(Symbol(className)),
      orElse: () => throw Exception('Classe $className não encontrada.'),
    );
    final classMirror = libraryMirror.declarations[Symbol(className)] as ClassMirror;

    return classMirror;
  }

  //CREATE TABLE
  static Future<void> generateCreateTableSql(Type type) async { 

    try{

      final classMirror = reflectClass(type);

      final tableAnnotation = classMirror.metadata
          .firstWhere((m) => m.reflectee is Table)
          .reflectee as Table;

      final fields = <String>[];

      for (var decl in classMirror.declarations.values) {
        if (decl is VariableMirror && decl.metadata.isNotEmpty) {
          final columnAnn = decl.metadata
              .firstWhere((m) => m.reflectee is Column)
              .reflectee as Column;

          final typeStr = _dartTypeToSqlType(decl.type.reflectedType, primaryKey: columnAnn.primaryKey);
          final pk = columnAnn.primaryKey ? 'PRIMARY KEY' : '';
          fields.add('${columnAnn.name} $typeStr $pk');
        }
      }

      await Database.connection.execute(
        'CREATE TABLE IF NOT EXISTS ${tableAnnotation.name} (${fields.join(', ')});'
      );
      return;

    }catch(e){
      throw Exception('Falha ao criar a tabela: ${type.toString()}. \nDescricao do erro: $e');
    }
  }

  //DROP TABLE
  static Future<void> generateDropTableSql(Type type) async { 
    try{  
      final classMirror = reflectClass(type);
      final tableAnn = classMirror.metadata
          .firstWhere((m) => m.reflectee is Table)
          .reflectee as Table;
      await Database.connection.execute('DROP TABLE IF EXISTS ${tableAnn.name};');
      return ;
    }catch(e){
      throw Exception('Falha ao deletar a tabela: ${type.toString()}. \nDescricao do erro: $e');
    }
  }

  //Query ALL
  static Future<List<Map<String, dynamic>>> queryAll(String className) async {
    try {
      
      final classMirror = getClassMirror(className);

      final tableAnn = classMirror.metadata
          .firstWhere((m) => m.reflectee is Table)
          .reflectee as Table;

      final result = await Database.connection.mappedResultsQuery(
        'SELECT * FROM ${tableAnn.name};',
      );

      return result.map((row) => row.values.first).toList();
    } catch (e) {
      throw Exception('Erro ao buscar registros de $className: $e');
    }
  }

  //INSERT 
  static Future<void> insert(String className, List<Map<String, dynamic>> valuesList) async {
    try {
    

      final classMirror = getClassMirror(className);

      for (final data in valuesList) {
        final namedArgs = data.map((key, value) => MapEntry(Symbol(key), value));
        final instance = classMirror.newInstance(Symbol(''), [], namedArgs).reflectee;
        await (instance as Model).create();
      }

    } catch (e) {
      throw Exception('Erro ao inserir registros em $className: $e');
    } 
  }

  //UPDATE
  static Future<void> update(String className, Map<String, dynamic> values) async {
    try {

      final classMirror = getClassMirror(className);

      final namedArgs = values.map((key, value) => MapEntry(Symbol(key), value));
      final instance = classMirror.newInstance(Symbol(''), [], namedArgs).reflectee;

      await (instance as Model).create();

    } catch (e) {
      throw Exception('Erro ao atualizar $className: $e');
    }
  }

  //DELETE
  static Future<void> delete(String className, int id) async {
    try {

      final classMirror = getClassMirror(className);

      final instance = classMirror.newInstance(Symbol(''), [], {
        Symbol('id'): id,
      }).reflectee;

      await (instance as Model).delete();

    } catch (e) {
      throw Exception('Erro ao deletar registro de $className com id $id: $e');
    }
  }

  //Encontrar através do ID
  static Future<Map<String, dynamic>?> findById(String className, int id) async {
    try {

      final classMirror = getClassMirror(className);

      final tableAnn = classMirror.metadata
          .firstWhere((m) => m.reflectee is Table)
          .reflectee as Table;

      final result = await Database.connection.mappedResultsQuery(
        'SELECT * FROM ${tableAnn.name} WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': id},
      );

      if (result.isEmpty) return null;

      return result.first.values.first;
    } catch (e) {
      throw Exception('Erro ao buscar $className com id $id: $e');
    }
  }


  static String _dartTypeToSqlType(Type t, {bool primaryKey = false}) {
    if (t == int && primaryKey) return 'SERIAL';
    if (t == int) return 'INTEGER';
    if (t == String) return 'TEXT';
    throw UnsupportedError('Tipo $t não suportado');
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

