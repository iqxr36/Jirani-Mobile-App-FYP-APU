part of '../resident_chat_thread_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const int _kMaxImageBytes = 10 * 1024 * 1024;
const int _kMaxFileBytes = 25 * 1024 * 1024;
const int _kMaxVideoBytes = 50 * 1024 * 1024;

const Set<String> _kImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
const Set<String> _kVideoExtensions = {'mp4', 'mov', 'm4v', 'webm'};
const Set<String> _kDocumentExtensions = {
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'csv',
};

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }
  if (bytes >= 1024) {
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
  }
  return '$bytes B';
}

class _PickedChatAttachment {
  const _PickedChatAttachment({
    required this.fileName,
    required this.type,
    required this.fileSize,
    this.bytes,
    this.localFilePath,
  });

  final String fileName;
  final String type;
  final int fileSize;
  final Uint8List? bytes;
  final String? localFilePath;

  bool get isImage => type == AppConstants.chatMessageImage;
}

enum _AttachmentAction { photo, file }
