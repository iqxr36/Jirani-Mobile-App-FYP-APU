import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/verification/verification_permission_flow_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);

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

  Widget _buildStatusCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ResidentIcon(),
            const SizedBox(height: 12),
            const Text(
              'Account Created!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kBrandTeal,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Confirm your community location to\nenter restricted access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Full access unlocks after admin\napproval of your documents.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
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

  Widget _buildSignOutButton(AuthViewModel viewModel) {
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
        onPressed: viewModel.isLoading ? null : viewModel.logout,
        child: const Text(
          'Sign out',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final padding = JiraniResponsive.pagePadding(context, top: 48, bottom: 24);

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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatusCard(context),
                        const Spacer(),
                        const SizedBox(height: 32),
                        _buildStartButton(context, viewModel),
                        const SizedBox(height: 12),
                        _buildSignOutButton(viewModel),
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

class _ResidentIcon extends StatelessWidget {
  const _ResidentIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      width: 76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.avatarPlaceholder,
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
                color: context.avatarPlaceholder,
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
