import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';

@HiveType(typeId: HiveTypeIds.category)
class Category extends HiveObject {
  Category({
    required this.id,
    required this.name,
    this.parentId,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String? parentId;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = HiveTypeIds.category;

  @override
  Category read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Category(
      id: fields[0] as String,
      name: fields[1] as String,
      parentId: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId);
  }
}


