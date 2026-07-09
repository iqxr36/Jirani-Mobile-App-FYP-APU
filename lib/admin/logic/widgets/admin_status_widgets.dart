import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_button_styles.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';

class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminSurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, color: color),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AdminStatusNotice extends StatelessWidget {
  const AdminStatusNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AdminColors.secondary.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AdminColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: AdminColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminInlineAlert extends StatelessWidget {
  const AdminInlineAlert({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.accent.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AdminColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class AdminEmptyPanelMessage extends StatelessWidget {
  const AdminEmptyPanelMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AdminColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.name,
    this.imageUrl = '',
    this.previewBytes,
    this.large = false,
    this.onImageError,
  });

  final String name;
  final String imageUrl;
  final Uint8List? previewBytes;
  final bool large;
  final void Function(Object error)? onImageError;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    final trimmedImageUrl = imageUrl.trim();
    final radius = large ? 34.0 : 18.0;
    final size = radius * 2;
    final hasPreview = previewBytes != null && previewBytes!.isNotEmpty;
    final hasRemoteImage = trimmedImageUrl.isNotEmpty;

    if (hasPreview) {
      return _avatarShell(
        radius: radius,
        child: Image.memory(
          previewBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (hasRemoteImage) {
      if (kIsWeb) {
        return _avatarShell(
          radius: radius,
          child: Image.network(
            trimmedImageUrl,
            key: ValueKey<String>(trimmedImageUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (context, error, stackTrace) {
              _notifyImageError(error);
              return _initialsFallback(radius, initial);
            },
          ),
        );
      }

      return _avatarShell(
        radius: radius,
        child: CachedNetworkImage(
          key: ValueKey<String>(trimmedImageUrl),
          imageUrl: trimmedImageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (context, url) => _initialsFallback(radius, initial),
          errorWidget: (context, url, error) {
            _notifyImageError(error);
            return _initialsFallback(radius, initial);
          },
        ),
      );
    }

    return _initialsFallback(radius, initial);
  }

  void _notifyImageError(Object error) {
    final callback = onImageError;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(error));
  }

  Widget _avatarShell({required double radius, required Widget child}) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: child,
      ),
    );
  }

  Widget _initialsFallback(double radius, String initial) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: large ? 24 : 14,
        ),
      ),
    );
  }
}

class AdminIdentityCell extends StatelessWidget {
  const AdminIdentityCell({
    super.key,
    required this.name,
    this.imageUrl = '',
  });

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AdminAvatar(name: name, imageUrl: imageUrl),
        const SizedBox(width: 10),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class AdminInfoTile extends StatelessWidget {
  const AdminInfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminFilterChipButton extends StatelessWidget {
  const AdminFilterChipButton({
    super.key,
    required this.label,
    this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = const Icon(Icons.filter_list_rounded);
    if (selected) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.primary.withValues(alpha: 0.14),
          foregroundColor: AdminColors.primary,
        ),
        icon: icon,
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      style: AdminButtonStyles.primaryOutlined(context),
      icon: icon,
      label: Text(label),
    );
  }
}

class AdminTonalActionButton extends StatelessWidget {
  const AdminTonalActionButton({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {},
      style: AdminButtonStyles.primaryTonal(context),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class AdminPriorityDot extends StatelessWidget {
  const AdminPriorityDot({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = priority == 'High'
        ? AdminColors.accent
        : priority == 'Med'
        ? AdminColors.warning
        : AdminColors.success;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(priority, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}
