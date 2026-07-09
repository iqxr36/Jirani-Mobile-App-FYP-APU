import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';

/// Shared admin button styles — primary actions follow the portal theme; destructive stay red.
class AdminButtonStyles {
  const AdminButtonStyles._();

  static ButtonStyle primaryFilled(BuildContext context) {
    return FilledButton.styleFrom(
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  static ButtonStyle primaryOutlined(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AdminColors.primary,
      side: BorderSide(color: AdminColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  static ButtonStyle primaryTonal(BuildContext context) {
    return FilledButton.styleFrom(
      backgroundColor: AdminColors.primary.withValues(alpha: 0.12),
      foregroundColor: AdminColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  static ButtonStyle dangerFilled(BuildContext context) {
    return FilledButton.styleFrom(
      backgroundColor: AdminColors.danger,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  static ButtonStyle dangerOutlined(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AdminColors.danger,
      side: const BorderSide(color: AdminColors.danger),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
