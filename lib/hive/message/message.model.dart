import 'package:hive/hive.dart';

part 'message.model.g.dart';

@HiveType(typeId: 2)
class MessageModel {
  @HiveField(0)
  int id;
  @HiveField(1)
  String content;
  @HiveField(2)
  DateTime createAt;
  @HiveField(3)
  bool status;
  @HiveField(4)
  String sender;
  @HiveField(5)
  String receiver;
  @HiveField(6)
  String type;

  MessageModel(this.id, this.content, this.createAt, this.status, this.receiver, this.sender, this.type);
}