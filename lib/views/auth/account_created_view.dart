import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/verification/verification_permission_flow_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 350;

/// Entry prompt for an unverified resident after authentication.
class AccountCreatedView extends StatelessWidget {
  const AccountCreatedView({super.key});

  Future<void> _startVerification(
    BuildContext context,
    AuthViewModel viewModel,
  ) async {
    final navigationContext = Navigator.of(context).overlay!.context;
    viewModel.dismissAccountCreatedScreen();
    await Navigator.of(navigationContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const VerificationPermissionFlowView(),
      ),
    );
  }

  Widget _buildStatusCard() {
    return SizedBox(
      height: 380,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Column(
            children: [
              _ResidentIcon(),
              SizedBox(height: 12),
              Text(
                'Account Created!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kBrandTeal,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 50),
              Text(
                'Your account is unverified until\nresidency verification is completed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Full access is restricted to verified\nresidents.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, AuthViewModel viewModel) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: viewModel.isLoading
            ? null
            : () => _startVerification(context, viewModel),
        child: const Text(
          'Start Verification',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildLaterButton(AuthViewModel viewModel) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF787880).withValues(alpha: 0.16),
          foregroundColor: _kBrandTeal,
          disabledForegroundColor: _kBrandTeal.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: viewModel.isLoading
            ? null
            : viewModel.dismissAccountCreatedScreen,
        child: const Text(
          'Do it later',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(26, 56, 26, 18 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const Spacer(),
                  _buildStartButton(context, viewModel),
                  const SizedBox(height: 12),
                  _buildLaterButton(viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResidentIcon extends StatelessWidget {
  const _ResidentIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      width: 76,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFCFE5E9),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: 17,
              top: 17,
              child: Icon(Icons.person, color: _kBrandTeal, size: 42),
            ),
            Positioned(
              right: 13,
              top: 23,
              child: Container(
                color: const Color(0xFFCFE5E9),
                width: 19,
                height: 19,
                child: const Icon(Icons.add, color: _kBrandTeal, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
