import 'package:hive/hive.dart';
import '../../models/photo_model.dart';
import 'hive_boxes.dart';

class PhotoLocalDataSource {
  final Box<PhotoModel> _box = HiveBoxes.photosBox;

  // Get all photos
  List<PhotoModel> getAllPhotos() {
    return _box.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  // Add photo
  Future<void> addPhoto(PhotoModel photo) async {
    await _box.put(photo.id, photo);
  }

  // Delete photo
  Future<void> deletePhoto(String id) async {
    await _box.delete(id);
  }

  // Update photo
  Future<void> updatePhoto(PhotoModel photo) async {
    await photo.save();
  }

  // Clear all photos
  Future<void> clearAll() async {
    await _box.clear();
  }

  // Reorder photos
  Future<void> reorderPhotos(List<PhotoModel> photos) async {
    for (var i = 0; i < photos.length; i++) {
      photos[i].order = i;
      await photos[i].save();
    }
  }
}
