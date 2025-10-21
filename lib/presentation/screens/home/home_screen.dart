import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/photo_provider.dart';
import '../settings/settings_screen.dart';
import '../slideshow/slideshow_screen.dart';
import 'widgets/photo_grid_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Frame'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: photos.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildPhotoGrid(context, ref, photos),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (photos.isNotEmpty)
            FloatingActionButton(
              heroTag: 'play',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SlideshowScreen(),
                  ),
                );
              },
              child: const Icon(Icons.play_arrow),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () async {
              await ref.read(photoProvider.notifier).addPhotosFromGallery();
            },
            child: const Icon(Icons.add_photo_alternate),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz fotoğraf eklemediniz',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Başlamak için fotoğraf ekleyin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(photoProvider.notifier).addPhotosFromGallery();
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Fotoğraf Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, WidgetRef ref, List photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return PhotoGridItem(
          photo: photos[index],
          onDelete: () async {
            await ref
                .read(photoProvider.notifier)
                .deletePhoto(photos[index].id);
          },
        );
      },
    );
  }
}
