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
            style: TextStyle(
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
  const AdminReportEvidencePreview({
    super.key,
    this.imageUrls = const <String>[],
    this.evidenceItems = const <AdminReportEvidenceItem>[],
  });

  final List<String> imageUrls;
  final List<AdminReportEvidenceItem> evidenceItems;

  @override
  Widget build(BuildContext context) {
    final candidates = _candidateItems();
    if (candidates.isEmpty) return const SizedBox.shrink();
    final hasBeforeAfter = candidates.any(
          (item) => item.label.toLowerCase().contains('before'),
        ) &&
        candidates.any((item) => item.label.toLowerCase().contains('after') ||
            item.label.toLowerCase().contains('dispute'));

    return FilledButton.tonalIcon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => _ProofEvidenceDialog(items: candidates),
      ),
      icon: const Icon(Icons.photo_library_rounded),
      label: Text(
        hasBeforeAfter
            ? 'Compare Photos'
            : candidates.length == 1
                ? 'View Proof'
                : 'View Proofs',
      ),
    );
  }

  List<AdminReportEvidenceItem> _candidateItems() {
    final seen = <String>{};
    final source = evidenceItems.isNotEmpty
        ? evidenceItems
        : imageUrls
            .map(
              (url) => AdminReportEvidenceItem(
                label: 'Proof photo',
                imageUrl: url,
              ),
            )
            .toList();
    final candidates = <AdminReportEvidenceItem>[];
    for (final item in source) {
      final trimmed = item.imageUrl.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      candidates.add(
        AdminReportEvidenceItem(
          label: item.label.trim().isEmpty ? 'Proof photo' : item.label.trim(),
          imageUrl: trimmed,
        ),
      );
    }
    return candidates;
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

class AdminReportEvidenceItem {
  const AdminReportEvidenceItem({
    required this.label,
    required this.imageUrl,
  });

  final String label;
  final String imageUrl;
}

class _ProofEvidenceDialog extends StatelessWidget {
  const _ProofEvidenceDialog({required this.items});

  final List<AdminReportEvidenceItem> items;

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
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final rawUrl = item.imageUrl;
                  return FutureBuilder<String?>(
                    future: AdminReportEvidencePreview._resolveEvidenceUrl(
                      rawUrl,
                    ),
                    builder: (context, snapshot) {
                      final loading =
                          snapshot.connectionState != ConnectionState.done;
                      final resolvedUrl = snapshot.data?.trim() ?? '';
                      return _ProofEvidenceTile(
                        label: item.label,
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
    required this.label,
    required this.rawUrl,
    required this.resolvedUrl,
    required this.loading,
  });

  final String label;
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
          Row(
            children: [
              Icon(
                Icons.image_search_rounded,
                color: AdminColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
