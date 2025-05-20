import 'dart:mirrors';
import '../database.dart';
import 'annotations.dart';
import 'query_builder.dart';

abstract class Model {

  Future<void> create() async {
    try{
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
            continue; 
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
    }catch(e){
      throw Exception('Falha ao criar o registro na tabela. \nDescricao do erro: $e');
    }
  }

  Future<void> delete() async {
      try{
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
    }catch(e){
      throw Exception('Falha ao deletar o registro na tabela. \nDescricao do erro: $e');
    }
  }

}
