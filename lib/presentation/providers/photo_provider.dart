import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/models/photo_model.dart';
import '../../data/datasources/local/photo_local_datasource.dart';

// DataSource provider
final photoDataSourceProvider = Provider((ref) => PhotoLocalDataSource());

// Photo list provider (StateNotifier kullanarak)
class PhotoNotifier extends StateNotifier<List<PhotoModel>> {
  final PhotoLocalDataSource _dataSource;

  PhotoNotifier(this._dataSource) : super([]) {
    _loadPhotos();
  }

  void _loadPhotos() {
    state = _dataSource.getAllPhotos();
  }

  // Add photo from gallery
  Future<void> addPhotosFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    for (var image in images) {
      // Copy image to app directory
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final savedPath = '${photoDir.path}/$fileName';
      await File(image.path).copy(savedPath);

      // Create photo model
      final photo = PhotoModel.create(savedPath);
      await _dataSource.addPhoto(photo);
    }

    _loadPhotos();
  }

  // Delete photo
  Future<void> deletePhoto(String id) async {
    final photo = state.firstWhere((p) => p.id == id);

    // Delete file
    final file = File(photo.path);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete from database
    await _dataSource.deletePhoto(id);
    _loadPhotos();
  }

  // Clear all
  Future<void> clearAll() async {
    // Delete all files
    for (var photo in state) {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await _dataSource.clearAll();
    _loadPhotos();
  }
}

// Provider export (Angular'daki service injection gibi)
final photoProvider =
    StateNotifierProvider<PhotoNotifier, List<PhotoModel>>((ref) {
  final dataSource = ref.watch(photoDataSourceProvider);
  return PhotoNotifier(dataSource);
});
