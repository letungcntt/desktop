import 'package:hive/hive.dart';

part 'person.model.g.dart';

@HiveType(typeId: 1)
class PersonModel {
  @HiveField(0)
  int id;
  @HiveField(1)
  String name;
  @HiveField(2)
  DateTime birthDate;

  @HiveField(3)
  bool status;
  PersonModel(this.id, this.name, this.birthDate, this.status);
}