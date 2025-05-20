import '../orm/annotations.dart';
import '../orm/model.dart';

@Table('users')
class User extends Model{
  @Column('id', primaryKey: true)
  int? id;

  @Column('name')
  String? name;

  @Column('email')
  String? email;

  @Column('idade')
  int? idade;

  User({this.id, this.name, this.email, this.idade});

}


@Table('animal')
class Animal extends Model{
  @Column('id', primaryKey: true)
  int? id;

  @Column('name')
  String? name;

  Animal({this.id, this.name});

  
}
