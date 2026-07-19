// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_thread_attachment_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_chat_thread_view.dart';

class _SafeImageMessageCard extends StatelessWidget {
  const _SafeImageMessageCard({
    required this.message,
    required this.isSentByMe,
  });

  final chat_core.ImageMessage message;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: isSentByMe
            ? _kBrandTeal.withValues(alpha: 0.12)
            : context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: Image.network(
              message.source,
              fit: BoxFit.cover,
              cacheWidth: 520,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: _kBrandTeal),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, color: _kBrandTeal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text?.trim().isNotEmpty == true
                        ? message.text!.trim()
                        : 'Photo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (message.size != null)
                  Text(
                    _formatBytes(message.size!),
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeFileMessageCard extends StatelessWidget {
  const _SafeFileMessageCard({
    required this.name,
    required this.mimeType,
    required this.size,
    required this.isSentByMe,
  });

  final String name;
  final String? mimeType;
  final int? size;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isSentByMe
            ? _kBrandTeal.withValues(alpha: 0.12)
            : context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForMimeType(mimeType, name), color: _kBrandTeal),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? 'Attachment' : name.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (mimeType?.trim().isNotEmpty == true) mimeType!.trim(),
                    if (size != null) _formatBytes(size!),
                  ].join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new_rounded, color: _kBrandTeal, size: 18),
        ],
      ),
    );
  }

  IconData _iconForMimeType(String? mimeType, String name) {
    final mime = mimeType?.toLowerCase() ?? '';
    final extension = p.extension(name).toLowerCase();
    if (mime.startsWith('video/') ||
        ['.mp4', '.mov', '.webm'].contains(extension)) {
      return Icons.play_circle_outline_rounded;
    }
    if (mime == 'application/pdf' || extension == '.pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

class _ImageAttachmentPreviewScreen extends StatelessWidget {
  const _ImageAttachmentPreviewScreen({required this.message});

  final chat_core.ImageMessage message;

  @override
  Widget build(BuildContext context) {
    final label = message.text?.trim().isNotEmpty == true
        ? message.text!.trim()
        : 'Photo';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            message.source,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfAttachmentPreviewScreen extends StatefulWidget {
  const _PdfAttachmentPreviewScreen({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  State<_PdfAttachmentPreviewScreen> createState() =>
      _PdfAttachmentPreviewScreenState();
}

class _PdfAttachmentPreviewScreenState
    extends State<_PdfAttachmentPreviewScreen> {
  late final PdfControllerPinch _pdfController;
  int _currentPage = 1;
  int? _pagesCount;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesCount = _pagesCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _kBrandTeal,
        foregroundColor: Colors.white,
        actions: [
          if (pagesCount != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $pagesCount',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewPinch(
        controller: _pdfController,
        onDocumentLoaded: (document) {
          setState(() => _pagesCount = document.pagesCount);
        },
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        onDocumentError: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this PDF.')),
          );
        },
      ),
    );
  }
}

class _AttachmentProgressDialog extends StatelessWidget {
  const _AttachmentProgressDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet();

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          Text(
            'Send Attachment',
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _SheetAction(
            icon: Icons.image_outlined,
            title: 'Photo',
            subtitle: 'Choose an image from gallery',
            onTap: () => Navigator.of(context).pop(_AttachmentAction.photo),
          ),
          const SizedBox(height: 10),
          _SheetAction(
            icon: Icons.attach_file_rounded,
            title: 'File',
            subtitle: 'Send a document or other file',
            onTap: () => Navigator.of(context).pop(_AttachmentAction.file),
          ),
        ],
      ),
    );
  }
}

class _MediaPreviewSheet extends StatelessWidget {
  const _MediaPreviewSheet({required this.attachment});

  final _PickedChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final bytes = attachment.bytes;
    return _SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const Text(
            'Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (attachment.isImage && bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(bytes, height: 220, fit: BoxFit.cover),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBrandTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: _kBrandTeal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatBytes(attachment.fileSize),
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: _kBrandTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

