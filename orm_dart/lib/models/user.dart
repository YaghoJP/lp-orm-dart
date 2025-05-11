import '../orm/annotations.dart';

@Table('users')
class User {
  @Column('id', primaryKey: true)
  int? id;

  @Column('name')
  String name;

  @Column('email')
  String email;

  User({this.id, required this.name, required this.email});
}

