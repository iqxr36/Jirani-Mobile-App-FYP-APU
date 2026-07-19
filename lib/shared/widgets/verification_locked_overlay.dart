// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_locked_overlay.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,13-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/verification_access.dart';
import 'package:jirani/shared/models/app_user.dart';

const Color _kBrandTeal = Color(0xFF006D77);

/// Blocks interaction on [child] until residency and location gates pass.
class VerificationLockedOverlay extends StatelessWidget {
  const VerificationLockedOverlay({
    super.key,
    required this.user,
    required this.child,
    this.showBannerWhenLocked = true,
  });

  final AppUser? user;
  final Widget child;
  final bool showBannerWhenLocked;

  @override
  Widget build(BuildContext context) {
    if (residentHasFullAppAccess(user)) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AbsorbPointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        if (showBannerWhenLocked)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _VerificationBanner(user: user),
          ),
      ],
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: _kBrandTeal, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                residentAccessMessage(user),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
