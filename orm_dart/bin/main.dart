import 'package:orm_dart/database.dart';
import 'package:orm_dart/orm/mapper.dart';
import 'package:orm_dart/models/user.dart';
import 'package:orm_dart/orm/model.dart';

void main() async {
  await Database.connect();

  final sql = OrmMapper.generateCreateTableSql(User);
  print('SQL gerado: $sql');

  await Database.connection.execute(sql);
  print('Tabela criada com sucesso!');
  print('');


  //TESTE INSERT
  final user = User(name: 'Raquel', email: 'rr@hotmail.com');
  await user.save();

  print('Usuário salvo com id: ${user.id}');

  print('');

  //TESTE SELECT
  print('Teste Select:');
  var users = await Model.all<User>(() => User(name: '', email: ''));
  for(var u in users){
    print('${u.id}, ${u.name}, ${u.email}');
  }

  print('');

  //TESTE UPDATE
  user.name = 'Raquel Real';
  user.email = 'rreal@hotmail.com';
  await user.save();
  print('Usuario ${user.id} atualizado!');

  users = await Model.all<User>(() => User(name: '', email: ''));
  for(var u in users){
    print('${u.id}, ${u.name}, ${u.email}');
  }

  print('');

  //TESTE DELETE
  await user.delete();
  print('Usuário ${user.id} deletado com sucesso.');

  users = await Model.all<User>(() => User(name: '', email: ''));
  for(var u in users){
    print('${u.id}, ${u.name}, ${u.email}');
  }

  print('Fim');
}

