import 'package:hive/hive.dart';

part 'workspace.model.g.dart';

@HiveType(typeId: 1)
class WorkspaceModel {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String ownerId;
  WorkspaceModel(this.id, this.name, this.ownerId);
}