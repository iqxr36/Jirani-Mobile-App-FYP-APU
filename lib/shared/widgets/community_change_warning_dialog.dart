import 'package:flutter/material.dart';

class CommunityChangeWarningDialog extends StatelessWidget {
  const CommunityChangeWarningDialog({
    super.key,
    required this.communityName,
    required this.isVerifiedResident,
    required this.onCancel,
    required this.onConfirm,
  });

  final String communityName;
  final bool isVerifiedResident;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxDialogHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 7, color: const Color(0xFFE29578)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE29578,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFFE29578,
                                ).withValues(alpha: 0.30),
                              ),
                            ),
                            child: const Icon(
                              Icons.move_down_rounded,
                              color: Color(0xFF9A4D2D),
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change community?',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF102B2A),
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    height: 1.12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Moving to $communityName will reset your access in your current community.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF556361),
                                    fontWeight: FontWeight.w500,
                                    height: 1.42,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (isVerifiedResident) ...[
                        const CommunityChangeWarningImpactRow(
                          icon: Icons.verified_user_outlined,
                          title: 'Verification will reset',
                          subtitle:
                              'You will become unverified in your current and new community.',
                        ),
                        const SizedBox(height: 8),
                        const CommunityChangeWarningImpactRow(
                          icon: Icons.lock_outline_rounded,
                          title: 'Resident features will lock',
                          subtitle:
                              'Borrowing, lending, services, and marketplace actions pause.',
                        ),
                        const SizedBox(height: 8),
                        const CommunityChangeWarningImpactRow(
                          icon: Icons.description_outlined,
                          title: 'Documents must be submitted again',
                          subtitle:
                              'Upload proof of residence for the new community.',
                        ),
                        const SizedBox(height: 8),
                      ],
                      const CommunityChangeWarningImpactRow(
                        icon: Icons.people_outline_rounded,
                        title: 'Neighbor connections will be removed',
                        subtitle:
                            'You will need to connect again in your new community.',
                      ),
                      const SizedBox(height: 8),
                      const CommunityChangeWarningImpactRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Previous chats will no longer be available',
                        subtitle:
                            "You won't be able to open or continue old conversations.",
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useStackedButtons = constraints.maxWidth < 330;
                          final cancelButton = OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              foregroundColor: const Color(0xFF173836),
                              side: const BorderSide(color: Color(0xFFD8E8E6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Keep Current'),
                          );
                          final confirmButton = FilledButton(
                            onPressed: onConfirm,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: const Color(0xFF006D77),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Change Community'),
                          );

                          if (useStackedButtons) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                confirmButton,
                                const SizedBox(height: 10),
                                cancelButton,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: cancelButton),
                              const SizedBox(width: 10),
                              Expanded(child: confirmButton),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class CommunityChangeWarningImpactRow extends StatelessWidget {
  const CommunityChangeWarningImpactRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1D7C8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9A4D2D), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D211C),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF675247),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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
