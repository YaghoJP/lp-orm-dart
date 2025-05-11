import 'package:orm_dart/database.dart';
import 'package:orm_dart/orm/mapper.dart';
import 'package:orm_dart/models/user.dart';

void main() async {
  await Database.connect();

  final sql = OrmMapper.generateCreateTableSql(User);
  print('SQL gerado: $sql');

  await Database.connection.execute(sql);
  print('Tabela criada com sucesso!');
}

