import 'package:flutter/material.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 350;

/// Confirms that the resident is currently within the selected community area.
class LocationVerifiedView extends StatelessWidget {
  const LocationVerifiedView({
    super.key,
    required this.communityName,
  });

  final String communityName;

  void _continueToVerification(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 255,
      width: double.infinity,
      child: Image.asset(
        'assets/Location1.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.location_on_rounded,
            size: 112,
            color: _kBrandTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'COMMUNITY',
                  style: TextStyle(
                    color: Color(0xFF737378),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    communityName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.20)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'STATUS',
                  style: TextStyle(
                    color: Color(0xFF737378),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFBCEAC9),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Color(0xFF15652C),
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.black,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => _continueToVerification(context),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter Trust Community',
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
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
                  _buildIllustration(),
                  const SizedBox(height: 12),
                  const Text(
                    'You are within your selected\ncommunity area.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'You can now continue with residency\n'
                    'verification while full access remains restricted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF737378),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildResultCard(),
                  const Spacer(),
                  _buildContinueButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
