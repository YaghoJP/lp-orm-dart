import 'package:orm_dart/database.dart';
import 'package:orm_dart/orm/orm.dart';
import 'package:orm_dart/models/models.dart';
import 'package:orm_dart/orm/model.dart';


void showResut(List<Map<String, dynamic>> list){

  for (var l in list){
    print(l);
  }
}

void main() async {
  await Database.connect();

  try{

    print('\n');
    print('----------Testando com User----------');

    // DROP TABLE
    print('\n');
    print('Executando DROP');
    await Orm.generateDropTableSql(User);
    print('Tabela excluída (caso existisse).');
    print('\n');

    // CREATE TABLE
    print('Criando a tabela user');
    await Orm.generateCreateTableSql(User);
    print('Tabela User foi criada com sucesso.');
    print('\n');

    print('Inserindo 5 usuários.');
    await Orm.insert('User', [
      {
        'name': 'Lourdes', 'email': 'lu@gmail.com', 'idade': 52
      },
      {
        'name': 'Juiano', 'email': 'juliano@gmail.com', 'idade': 27
      },
      {
        'name': 'Joao', 'email': 'joao@gmail.com', 'idade': 22
      },
      {
        'name': 'Raquel', 'email': 'raquel@gmail.com', 'idade': 22
      },
      {
        'name': 'Tom', 'email': 'jerry@gmail.com', 'idade': 23
      }
    ]);  

    // SELECT ALL
    print('\nTodos os usuários após INSERT:');
    final users = await Orm.queryAll('User');
    //print(users);
    showResut(users);
    print('\n');


    print('\nFazendo um Update no usuário com ID = 4:');
    await Orm.update('User', {
      'id':4, 'name': 'Raimunda', 'email': 'raquel@gmail.com', 'idade': 22
    });
    final userUpdate = await Orm.findById('User', 4);
    print(userUpdate);
    print('\n');


    print('Buscando User por ID = 3');
    final userFind = await Orm.findById('User', 3);
    print(userFind);
    print('\n');


    print('Excluindo o User pelo ID  = 3');
    await Orm.delete('User', 3);
    final usersDelete = await Orm.queryAll('User');
    showResut(usersDelete);
    print('\n');

    print('----------Fim dos testes com User----------');

    print('\n');

    print('----------Testando com Animal----------');

    // DROP TABLE
    print('\n');
    print('Executando DROP');
    await Orm.generateDropTableSql(Animal);
    print('Tabela excluída (caso existisse).');
    print('\n');

    // CREATE TABLE
    print('Criando a tabela Animal');
    await Orm.generateCreateTableSql(Animal);
    print('Tabela Animal foi criada com sucesso.');
    print('\n');

    print('Inserindo 5 animais.');
    await Orm.insert('Animal', [
      {
        'name': 'Cachorro'
      },
      {
        'name': 'Pato'
      },
      {
        'name': 'Ganso'
      },
      {
        'name': 'Jabuti'
      },
      {
        'name': 'Elefante'
      }
    ]);  

    // SELECT ALL
    print('\nTodos os usuários após INSERT:');
    final animals = await Orm.queryAll('Animal');
    showResut(animals);
    print('\n');


    print('\nFazendo um Update no animal com ID = 4:');
    await Orm.update('Animal', {
      'id':4, 'name': 'Aranha'
    });
    final animalUpdate = await Orm.findById('Animal', 4);
    print(animalUpdate);
    print('\n');


    print('Buscando User por ID = 3');
    final animalFind = await Orm.findById('Animal', 3);
    print(animalFind);
    print('\n');


    print('Excluindo o User pelo ID  = 3');
    await Orm.delete('Animal', 3);
    final animalsDelete = await Orm.queryAll('Animal');
    showResut(animalsDelete);
    print('\n');

    print('----------Fim dos testes com User----------');

    print('\n');

  }catch(e){

    print('Error: $e');

  }
    
}

