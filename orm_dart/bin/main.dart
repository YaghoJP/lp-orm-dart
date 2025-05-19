import 'package:orm_dart/database.dart';
import 'package:orm_dart/orm/mapper.dart';
import 'package:orm_dart/models/user.dart';
import 'package:orm_dart/orm/model.dart';

void main() async {
  await Database.connect();

  // DROP TABLE
  final dropSql = OrmMapper.generateDropTableSql(User);
  print('Executando DROP: $dropSql');
  await Database.connection.execute(dropSql);
  print('Tabela excluída (caso existisse).');

  // CREATE TABLE
  final createSql = OrmMapper.generateCreateTableSql(User);
  print('Executando CREATE: $createSql');
  await Database.connection.execute(createSql);
  print('Tabela criada com sucesso!');

  // INSERT
  final user = User(name: 'Raquel', email: 'rr@hotmail.com');
  await user.save();
  print('Usuário inserido com ID: ${user.id}');

  // SELECT ALL
  print('\nTodos os usuários após INSERT:');
  var allUsers = await Model.all<User>(() => User(name: '', email: ''));
  for (var u in allUsers) {
    print('${u.id}, ${u.name}, ${u.email}');
  }

  // UPDATE
  user.name = 'Raquel Real';
  user.email = 'rreal@hotmail.com';
  user.idade = 22;
  await user.save();
  print('\nUsuário atualizado.');

  var allUsers2 = await Model.all<User>(() => User(name: '', email: ''));
  print('Todos os usuários após UPDATE:');
  for (var u in allUsers2) {
    print('${u.id}, ${u.name}, ${u.email}');
  }

  // FIND BY ID
  final found = await Model.findById<User>(user.id!, () => User(name: '', email: ''));
  print('\nUsuário encontrado por ID ${user.id}:');
  if (found != null) {
    print('${found.id}, ${found.name}, ${found.email}');
  } else {
    print('Usuário não encontrado');
  }

  // QUERY PERSONALIZADA
  print("\nQuery Personalizada: ");
  final filteredUsers = await User.query(
    'SELECT id, name, email, idade FROM users WHERE idade > @idade',
    {'idade': 18},
  );
  for (final user in filteredUsers) {
    print('${user.name} (${user.idade} anos) - ${user.email}');
  }

  // DELETE
  await user.delete();
  print('\nUsuário ${user.id} deletado.');

  final remainingUsers = await Model.all<User>(() => User(name: '', email: ''));
  print('Todos os usuários após DELETE:');
  for (var u in remainingUsers) {
    print('${u.id}, ${u.name}, ${u.email}');
  }

  print('Fim');
}
