// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisitAdapter extends TypeAdapter<Visit> {
  @override
  final int typeId = 1;

  @override
  Visit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Visit(
      id: fields[0] as int?,
      customerId: fields[1] as int,
      visitDate: fields[2] as DateTime,
      status: fields[3] as VisitStatus,
      location: fields[4] as String,
      notes: fields[5] as String?,
      activitiesDone: (fields[6] as List?)?.cast<int>(),
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Visit obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.visitDate)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.activitiesDone)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VisitStatusAdapter extends TypeAdapter<VisitStatus> {
  @override
  final int typeId = 0;

  @override
  VisitStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VisitStatus.completed;
      case 1:
        return VisitStatus.pending;
      case 2:
        return VisitStatus.cancelled;
      default:
        return VisitStatus.completed;
    }
  }

  @override
  void write(BinaryWriter writer, VisitStatus obj) {
    switch (obj) {
      case VisitStatus.completed:
        writer.writeByte(0);
        break;
      case VisitStatus.pending:
        writer.writeByte(1);
        break;
      case VisitStatus.cancelled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
