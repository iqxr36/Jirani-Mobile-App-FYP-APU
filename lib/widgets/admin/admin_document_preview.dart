import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(documentUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid document URL.')),
      );
      return;
    }
    final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = Row(
      children: [
        IconButton(
          tooltip: 'Zoom (placeholder)',
          onPressed: () {},
          icon: const Icon(Icons.zoom_in_outlined),
        ),
        IconButton(
          tooltip: 'Print (placeholder)',
          onPressed: () {},
          icon: const Icon(Icons.print_outlined),
        ),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: documentUrl.isEmpty ? null : () => _open(context),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open Document'),
        ),
      ],
    );

    if (documentUrl.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          toolbar,
          const SizedBox(height: 8),
          const Text('No uploaded document was found for this request.'),
          const SizedBox(height: 6),
          const Text(
            'Check Firestore field: documentUrl / fileUrl / uploadedFileUrl.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }
    if (_isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          toolbar,
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: const Color(0xFFF1F4F4),
              child: Image.network(
                documentUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Preview unavailable. Open the document in a new tab.'),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        toolbar,
        const SizedBox(height: 8),
        const Text('Preview unavailable. Open the document in a new tab.'),
      ],
    );
  }
}
