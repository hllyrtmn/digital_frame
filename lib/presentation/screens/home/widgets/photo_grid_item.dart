import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/photo_model.dart';

class PhotoGridItem extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onDelete;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(photo.path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(4),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Fotoğrafı Sil'),
                  content: const Text(
                      'Bu fotoğrafı silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
