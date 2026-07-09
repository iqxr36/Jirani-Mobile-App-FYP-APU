import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

const _payoutChannelOptions = <_PayoutChannelOption>[
  _PayoutChannelOption(label: 'Maybank', code: 'MY_MAYBANK'),
  _PayoutChannelOption(label: 'CIMB Bank', code: 'MY_CIMB'),
  _PayoutChannelOption(label: 'Public Bank', code: 'MY_PUBLIC_BANK'),
  _PayoutChannelOption(label: 'Hong Leong Bank', code: 'MY_HLB'),
  _PayoutChannelOption(label: 'RHB Bank', code: 'MY_RHB'),
  _PayoutChannelOption(label: "Touch 'n Go eWallet", code: 'MY_TNG'),
];

bool _isAllowedPayoutChannel(String code) {
  return _payoutChannelOptions.any((option) => option.code == code);
}

class _PayoutChannelOption {
  const _PayoutChannelOption({required this.label, required this.code});

  final String label;
  final String code;
}

/// Payments feature screen: explains checkout and lets residents configure test payout details.
class PaymentMethodsView extends StatefulWidget {
  const PaymentMethodsView({super.key});

  @override
  State<PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<PaymentMethodsView> {
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  var _selectedChannelCode = _payoutChannelOptions.first.code;
  var _initializedFromProfile = false;
  var _saving = false;

  @override
  void dispose() {
    _accountName.dispose();
    _accountNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final user = context.watch<AuthViewModel>().currentUser;

    if (user != null && !_initializedFromProfile) {
      final savedChannel = user.xenditPayoutChannel.trim();
      if (_isAllowedPayoutChannel(savedChannel)) {
        _selectedChannelCode = savedChannel;
      }
      _accountName.text = user.payoutAccountName;
      _initializedFromProfile = true;
    }

    return JiraniBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 18),
                    _PaymentsInfoPanel(user: user),
                    const SizedBox(height: 14),
                    _PayoutSetupPanel(
                      user: user,
                      selectedChannelCode: _selectedChannelCode,
                      onChannelChanged: (value) => setState(
                        () => _selectedChannelCode = value,
                      ),
                      accountName: _accountName,
                      accountNumber: _accountNumber,
                      saving: _saving,
                      onSave: user == null ? null : _savePayoutAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePayoutAccount() async {
    if (_saving) return;
    final channel = _selectedChannelCode.trim().toUpperCase();
    final accountName = _accountName.text.trim();
    final accountNumber = _accountNumber.text.trim();
    if (!_isAllowedPayoutChannel(channel) ||
        accountName.isEmpty ||
        accountNumber.isEmpty) {
      _showSnack('Fill in all payout account fields.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('saveTestPayoutAccount').call({
        'xenditPayoutChannel': channel,
        'payoutAccountName': accountName,
        'payoutAccountNumber': accountNumber,
      });
      if (!mounted) return;
      await context.read<AuthViewModel>().refreshCurrentUser();
      _accountNumber.clear();
      if (!mounted) return;
      _showSnack('Payout account verified for test mode.');
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        _showSnack(
          'Payout setup function is not deployed yet. Deploy Firebase Functions and try again.',
        );
      } else {
        _showSnack(e.message ?? 'Could not save payout account.');
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PaymentsInfoPanel extends StatelessWidget {
  const _PaymentsInfoPanel({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: _kBrandTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secure Payments',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Payments are handled by Xendit checkout. Fixed-job services pay providers only after completion code verification.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Requester checkout',
            body:
                'Residents pay through Xendit hosted checkout using local payment channels.',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.payments_rounded,
            title: 'Service provider payouts',
            body: user?.hasVerifiedPayoutAccount == true
                ? 'Your payout account is verified for test mode.'
                : 'Add payout details before publishing paid services.',
          ),
        ],
      ),
    );
  }
}

class _PayoutSetupPanel extends StatelessWidget {
  const _PayoutSetupPanel({
    required this.user,
    required this.selectedChannelCode,
    required this.onChannelChanged,
    required this.accountName,
    required this.accountNumber,
    required this.saving,
    required this.onSave,
  });

  final AppUser? user;
  final String selectedChannelCode;
  final ValueChanged<String> onChannelChanged;
  final TextEditingController accountName;
  final TextEditingController accountNumber;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verified = user?.hasVerifiedPayoutAccount == true;
    final masked = user?.payoutAccountMaskedIdentifier.trim() ?? '';
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : Icons.account_balance_wallet_outlined,
                color: _kBrandTeal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payout Account',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: verified ? 'Verified' : 'Missing',
                verified: verified,
              ),
            ],
          ),
          if (masked.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Saved account: $masked',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _isAllowedPayoutChannel(selectedChannelCode)
                ? selectedChannelCode
                : _payoutChannelOptions.first.code,
            decoration: _inputDecoration(
              context,
              label: 'Payout bank / e-wallet',
              hint: 'Choose payout destination',
            ),
            items: _payoutChannelOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.code,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: saving
                ? null
                : (value) {
                    if (value != null) onChannelChanged(value);
                  },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: accountName,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              context,
              label: 'Account holder name',
              hint: 'Name registered with bank/e-wallet',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: accountNumber,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            decoration: _inputDecoration(
              context,
              label: 'Account number / e-wallet ID',
              hint: verified ? 'Enter again to replace saved account' : 'e.g. 1234567890',
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(saving ? 'Saving...' : 'Save & Verify Test Account'),
          ),
          const SizedBox(height: 8),
          Text(
            'Test mode auto-verifies these details so service payouts can be exercised end to end.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: scheme.surface.withValues(alpha: 0.78),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kBrandTeal, width: 1.6),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.verified});

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? _kBrandTeal : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, size: 32),
              color: _kBrandTeal,
              tooltip: 'Back',
            ),
          ),
          const Text(
            'Payments',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _kBrandTeal, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
