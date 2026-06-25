part of '../admin_reports_screen.dart';

class AdminReportDetailSection extends StatelessWidget {
  const AdminReportDetailSection({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: const TextStyle(color: AdminColors.ink)),
            ),
        ],
      ),
    );
  }
}

class AdminReportEvidencePreview extends StatelessWidget {
  const AdminReportEvidencePreview({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final candidates = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (candidates.isEmpty) return const SizedBox.shrink();

    return FilledButton.tonalIcon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => _ProofEvidenceDialog(imageUrls: candidates),
      ),
      icon: const Icon(Icons.photo_library_rounded),
      label: Text(candidates.length == 1 ? 'View Proof' : 'View Proofs'),
    );
  }

  static Future<String?> _resolveEvidenceUrl(String rawUrl) async {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;
    try {
      if (value.startsWith('gs://')) {
        return FirebaseStorage.instance.refFromURL(value).getDownloadURL();
      }
      if (value.startsWith('http')) {
        if (value.contains('firebasestorage.googleapis.com')) {
          try {
            return await FirebaseStorage.instance
                .refFromURL(value)
                .getDownloadURL();
          } catch (_) {
            return value;
          }
        }
        return value;
      }
      return FirebaseStorage.instance.ref().child(value).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}

class _ProofEvidenceDialog extends StatelessWidget {
  const _ProofEvidenceDialog({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Proof Evidence',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AdminColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: imageUrls.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final rawUrl = imageUrls[index];
                  return FutureBuilder<String?>(
                    future: AdminReportEvidencePreview._resolveEvidenceUrl(
                      rawUrl,
                    ),
                    builder: (context, snapshot) {
                      final loading =
                          snapshot.connectionState != ConnectionState.done;
                      final resolvedUrl = snapshot.data?.trim() ?? '';
                      return _ProofEvidenceTile(
                        rawUrl: rawUrl,
                        resolvedUrl: resolvedUrl,
                        loading: loading,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofEvidenceTile extends StatelessWidget {
  const _ProofEvidenceTile({
    required this.rawUrl,
    required this.resolvedUrl,
    required this.loading,
  });

  final String rawUrl;
  final String resolvedUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 280, maxHeight: 460),
              color: AdminColors.surface,
              alignment: Alignment.center,
              child: loading
                  ? const CircularProgressIndicator()
                  : resolvedUrl.isEmpty
                      ? _EvidenceErrorMessage(rawUrl: rawUrl)
                      : Image.network(
                          resolvedUrl,
                          fit: BoxFit.contain,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.prefer,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 280,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _EvidenceErrorMessage(rawUrl: rawUrl);
                          },
                        ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: resolvedUrl.isEmpty
                    ? null
                    : () => launchUrl(
                          Uri.parse(resolvedUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Proof Link'),
              ),
              SizedBox(
                width: 520,
                child: SelectableText(
                  rawUrl,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceErrorMessage extends StatelessWidget {
  const _EvidenceErrorMessage({this.rawUrl = ''});

  final String rawUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      color: AdminColors.surface,
      padding: const EdgeInsets.all(16),
      child: Text(
        rawUrl.trim().isEmpty
            ? 'Could not load proof photo.'
            : 'Could not load proof photo. Stored reference: $rawUrl',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AdminColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
