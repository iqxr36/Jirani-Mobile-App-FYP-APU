import 'package:flutter/material.dart';

class AdminDocumentPreview extends StatelessWidget {
  const AdminDocumentPreview({
    super.key,
    required this.documentUrl,
  });

  final String documentUrl;

  bool get _isImage {
    final u = documentUrl.toLowerCase();
    return u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png') || u.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (documentUrl.isEmpty) {
      return const Text('No document URL available.');
    }
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          documentUrl,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Text('Document preview unavailable.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview unavailable for this file type.'),
        const SizedBox(height: 8),
        SelectableText(documentUrl),
      ],
    );
  }
}
