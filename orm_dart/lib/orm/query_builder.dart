import 'dart:mirrors';
import '../database.dart';
import 'model.dart';
import 'orm.dart';

class QueryBuilder<T extends Model> {
    final T Function() builder;
    final List<String> _conditions = [];
    final Map<String, dynamic> _substitutions = {};
    final List<String> _order = [];

    QueryBuilder(this.builder);

    QueryBuilder<T> where(String column, String op, dynamic value) {
        final param = 'param_${_substitutions.length}';
        _conditions.add('$column $op @$param');
        _substitutions[param] = value;
        return this;
    }

    QueryBuilder<T> whereEq(String column, dynamic value) {
        return where(column, '=', value);
    }

    QueryBuilder<T> whereGt(String column, dynamic value) {
        return where(column, '>', value);
    }

    QueryBuilder<T> whereLt(String column, dynamic value) {
        return where(column, '<', value);
    }

    QueryBuilder<T> orderBy(String column, {bool descending = false}) {
        _order.add('$column ${descending ? 'DESC' : 'ASC'}');
        return this;
    }

    Future<List<T>> get() async {
        final instance = builder();
        final mirror = reflect(instance);
        final classMirror = mirror.type;

        final tableAnn = classMirror.metadata
            .firstWhere((m) => m.reflectee.runtimeType.toString() == 'Table')
            .reflectee;

        final tableName = (tableAnn as dynamic).name;

        final columns = <String>[];
        for (var decl in classMirror.declarations.values) {
        if (decl is VariableMirror && decl.metadata.isNotEmpty) {
            final colAnn = decl.metadata
                .firstWhere((m) => m.reflectee.runtimeType.toString() == 'Column')
                .reflectee;
            columns.add((colAnn as dynamic).name);
        }
        }

        var sql = 'SELECT ${columns.join(', ')} FROM $tableName';
        if (_conditions.isNotEmpty) {
        sql += ' WHERE ${_conditions.join(' AND ')}';
        }
        if (_order.isNotEmpty) {
        sql += ' ORDER BY ${_order.join(', ')}';
        }

        return await Orm.query<T>(
        sql,
        substitutionValues: _substitutions,
        builder: builder,
        );
    }
}