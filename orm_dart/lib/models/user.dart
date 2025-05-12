import '../orm/annotations.dart';
import '../orm/model.dart';

@Table('users')
class User extends Model{
  @Column('id', primaryKey: true)
  int? id;

  @Column('name')
  String name;

  @Column('email')
  String email;

  User({this.id, required this.name, required this.email});
}

