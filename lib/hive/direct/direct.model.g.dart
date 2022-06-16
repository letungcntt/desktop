// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct.model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DirectModelAdapter extends TypeAdapter<DirectModel> {
  @override
  final int typeId = 4;

  @override
  DirectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DirectModel(
      fields[0] as String,
      (fields[1] as List).cast<dynamic>(),
      fields[2] as String,
      fields[3] as bool,
      fields[4] as int,
      fields[5] == null ? {} : (fields[5] as Map).cast<dynamic, dynamic>(),
      fields[6] == null ? false : fields[6] as bool,
      fields[7] == null ? 0 : fields[7] as int,
      fields[8] == null ? {} : (fields[8] as Map).cast<dynamic, dynamic>(),
      fields[9] == null ? '' : fields[9] as String,
      fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DirectModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.user)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.seen)
      ..writeByte(4)
      ..write(obj.newMessageCount)
      ..writeByte(5)
      ..write(obj.snippet)
      ..writeByte(6)
      ..write(obj.archive)
      ..writeByte(7)
      ..write(obj.updateByMessageTime)
      ..writeByte(8)
      ..write(obj.userRead)
      ..writeByte(9)
      ..write(obj.displayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
