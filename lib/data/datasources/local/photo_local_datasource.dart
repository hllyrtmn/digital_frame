import 'package:hive/hive.dart';
import '../../models/photo_model.dart';
import 'hive_boxes.dart';

class PhotoLocalDataSource {
  final Box<PhotoModel> _box = HiveBoxes.photosBox;

  List<PhotoModel> getAllPhotos() {
    return _box.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> addPhoto(PhotoModel photo) async {
    await _box.put(photo.id, photo);
  }

  Future<void> deletePhoto(String id) async {
    await _box.delete(id);
  }

  Future<void> updatePhoto(PhotoModel photo) async {
    await photo.save();
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> reorderPhotos(List<PhotoModel> photos) async {
    for (var i = 0; i < photos.length; i++) {
      photos[i].order = i;
      await photos[i].save();
    }
  }
}
