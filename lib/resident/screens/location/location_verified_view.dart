// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : location_verified_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);

/// Confirms that the resident is currently within the selected community area.
class LocationVerifiedView extends StatelessWidget {
  const LocationVerifiedView({super.key, required this.communityName});

  final String communityName;

  Future<void> _enterRestrictedApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await context.read<AuthViewModel>().markLocationVerified();
      if (!context.mounted) return;
      navigator.popUntil((route) => route.isFirst);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not save location verification. Try again.'),
        ),
      );
    }
  }

  Widget _buildIllustration(BuildContext context) {
    return SizedBox(
      height: JiraniResponsive.clamp(context, 220, minFactor: 0.78),
      width: double.infinity,
      child: Image.asset(
        'assets/Location1.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.location_on_rounded, size: 112, color: _kBrandTeal),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'COMMUNITY',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    communityName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: context.residentOutline()),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'STATUS',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFBCEAC9),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Color(0xFF15652C),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: context.appInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _enterRestrictedApp(context),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter Restricted Access',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 21),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = JiraniResponsive.pagePadding(context, top: 16, bottom: 24);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: padding,
              child: JiraniResponsiveCenter(
                width: JiraniContentWidth.auth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight > padding.vertical
                        ? constraints.maxHeight - padding.vertical
                        : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Text(
                          'Location Verified',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _kBrandTeal,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildIllustration(context),
                        const SizedBox(height: 12),
                        Text(
                          'You are within your selected\ncommunity area.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'You can now browse the app in restricted mode.\n'
                          'Submit verification documents from Profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildResultCard(context),
                        const Spacer(),
                        const SizedBox(height: 24),
                        _buildContinueButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
