import 'package:hive/hive.dart';

part 'channel.model.g.dart';

@HiveType(typeId: 3)
class ChannelModel {
  @HiveField(0)
  var id;
  @HiveField(1)
  var content;
  @HiveField(2)
  var createAt;
  @HiveField(3)
  var workspaceId;
  @HiveField(4)
  var status;
  @HiveField(5)
  bool isPrivate;

  ChannelModel(this.id, this.content, this.createAt, this.workspaceId, this.isPrivate);
}
