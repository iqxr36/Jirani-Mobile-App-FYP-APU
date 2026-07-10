import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/utils/profile_image_url_resolver.dart';

/// Profile image feature: resolves Firebase Storage references before showing an avatar.
class ResolvedProfileAvatar extends StatelessWidget {
  const ResolvedProfileAvatar({
    super.key,
    required this.photoReference,
    required this.name,
    this.radius = 18,
    this.initialsColor,
    this.placeholderColor,
  });

  final String photoReference;
  final String name;
  final double radius;
  final Color? initialsColor;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final reference = photoReference.trim();
    final initials = _initials(name);

    if (reference.isEmpty) {
      return _placeholderAvatar(
        initials: initials,
        placeholderColor: placeholderColor,
        initialsColor: initialsColor,
      );
    }

    return FutureBuilder<String?>(
      future: resolveProfileImageDisplayUrl(reference),
      builder: (context, snapshot) {
        final displayUrl = snapshot.data?.trim() ?? '';
        if (displayUrl.isEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: placeholderColor ?? Colors.black12,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return _placeholderAvatar(
            initials: initials,
            placeholderColor: placeholderColor,
            initialsColor: initialsColor,
          );
        }

        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: displayUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, _) => CircleAvatar(
              radius: radius,
              backgroundColor: placeholderColor ?? Colors.black12,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => _placeholderAvatar(
              initials: initials,
              placeholderColor: placeholderColor,
              initialsColor: initialsColor,
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderAvatar({
    required String initials,
    Color? placeholderColor,
    Color? initialsColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: placeholderColor ?? Colors.black12,
      child: Text(
        initials,
        style: TextStyle(
          color: initialsColor ?? Colors.teal,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'R';
    return trimmed
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
        .join();
  }
}
