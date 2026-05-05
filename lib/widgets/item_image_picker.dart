import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ItemImagePicker extends StatefulWidget {
  const ItemImagePicker({
    super.key,
    required this.initialImagePaths,
    required this.onChanged,
  });

  final List<String> initialImagePaths;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ItemImagePicker> createState() => _ItemImagePickerState();
}

class _ItemImagePickerState extends State<ItemImagePicker> {
  final _picker = ImagePicker();
  late List<String> _paths;

  @override
  void initState() {
    super.initState();
    _paths = List<String>.from(widget.initialImagePaths);
  }

  Future<void> _addFromGallery() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() {
      _paths.addAll(files.map((x) => x.path));
    });
    widget.onChanged(_paths);
  }

  Future<void> _addFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    setState(() {
      _paths.add(file.path);
    });
    widget.onChanged(_paths);
  }

  void _removeAt(int i) {
    setState(() {
      _paths.removeAt(i);
    });
    widget.onChanged(_paths);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item images', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_paths.isNotEmpty)
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _paths.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_paths[i]),
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: InkWell(
                        onTap: () => _removeAt(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _addFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add Images'),
            ),
            OutlinedButton.icon(
              onPressed: _addFromCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
          ],
        ),
      ],
    );
  }
}
