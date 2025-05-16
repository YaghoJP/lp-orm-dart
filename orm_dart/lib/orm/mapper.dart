import 'dart:mirrors';
import 'annotations.dart';

class OrmMapper {
  static String generateCreateTableSql(Type type) { //CREATE
    final classMirror = reflectClass(type);

    // Pega nome da tabela
    final tableAnnotation = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;

    final fields = <String>[];

    // Itera nos campos
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

    return 'CREATE TABLE IF NOT EXISTS ${tableAnnotation.name} (${fields.join(', ')});';
  }

  static String generateDropTableSql(Type type) { //DROP
    final classMirror = reflectClass(type);
    final tableAnn = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;
    return 'DROP TABLE IF EXISTS ${tableAnn.name};';
  }

  static List<String> generateAlterTableAddColumnsSql(Type type, List<String> existingColumns) { //ALTER ADD COLUMN
    final classMirror = reflectClass(type);
    final tableAnn = classMirror.metadata
        .firstWhere((m) => m.reflectee is Table)
        .reflectee as Table;

    final alters = <String>[];

    for (var decl in classMirror.declarations.values) {
      if (decl is VariableMirror && decl.metadata.isNotEmpty) {
        final colAnn = decl.metadata
            .firstWhere((m) => m.reflectee is Column)
            .reflectee as Column;

        if (!existingColumns.contains(colAnn.name)) {
          final sqlType = _dartTypeToSqlType(decl.type.reflectedType);
          alters.add('ALTER TABLE ${tableAnn.name} ADD COLUMN ${colAnn.name} $sqlType;');
        }
      }
    }

    return alters;
  }

  static String _dartTypeToSqlType(Type t, {bool primaryKey = false}) {
    if (t == int && primaryKey) return 'SERIAL';
    if (t == int) return 'INTEGER';
    if (t == String) return 'TEXT';
    throw UnsupportedError('Tipo $t não suportado');
  }
}

