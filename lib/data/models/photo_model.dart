import 'package:hive/hive.dart';

part 'photo_model.g.dart';

@HiveType(typeId: 0)
class PhotoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final DateTime addedAt;

  @HiveField(3)
  int order;

  PhotoModel({
    required this.id,
    required this.path,
    required this.addedAt,
    this.order = 0,
  });

  factory PhotoModel.create(String path) {
    return PhotoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      addedAt: DateTime.now(),
    );
  }

  PhotoModel copyWith({
    String? id,
    String? path,
    DateTime? addedAt,
    int? order,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
      order: order ?? this.order,
    );
  }
}
