// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : suspended_account_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/resident/screens/legal/legal_document_view.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

class SuspendedAccountView extends StatefulWidget {
  const SuspendedAccountView({
    super.key,
    required this.user,
    required this.onCheckStatus,
    required this.onSignOut,
  });

  final AppUser user;
  final Future<void> Function() onCheckStatus;
  final Future<void> Function() onSignOut;

  @override
  State<SuspendedAccountView> createState() => _SuspendedAccountViewState();
}

class _SuspendedAccountViewState extends State<SuspendedAccountView> {
  Timer? _expiryTimer;
  bool _checking = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _scheduleExpiryRefresh();
  }

  @override
  void didUpdateWidget(covariant SuspendedAccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.suspensionEndsAt != widget.user.suspensionEndsAt) {
      _scheduleExpiryRefresh();
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpiryRefresh() {
    _expiryTimer?.cancel();
    final endsAt = widget.user.suspensionEndsAt;
    if (endsAt == null) return;
    final remaining = endsAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      scheduleMicrotask(widget.onCheckStatus);
      return;
    }
    _expiryTimer = Timer(remaining, widget.onCheckStatus);
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onCheckStatus();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _openLegalDocument(JiraniLegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JiraniLegalDocumentView(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reason = widget.user.suspendedReason.trim();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return JiraniBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 28 + bottomInset),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          children: [
                            Semantics(
                              label: 'Account suspended',
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_clock_outlined,
                                  size: 38,
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Account temporarily suspended',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              suspensionAvailabilityText(widget.user),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    height: 1.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reason',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(reason),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _checking ? null : _checkStatus,
                                icon: _checking
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _checking
                                      ? 'Checking…'
                                      : 'Check account status',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _signingOut ? null : _signOut,
                                icon: const Icon(Icons.logout_rounded),
                                label: Text(
                                  _signingOut ? 'Signing out…' : 'Sign out',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Review Jirani’s rules while your account is unavailable.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => _openLegalDocument(
                            JiraniLegalDocument.communityGuidelines,
                          ),
                          child: const Text('Community Guidelines'),
                        ),
                        TextButton(
                          onPressed: () => _openLegalDocument(
                            JiraniLegalDocument.termsOfService,
                          ),
                          child: const Text('Terms of Service'),
                        ),
                      ],
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
}

String suspensionAvailabilityText(AppUser user) {
  final endsAt = user.suspensionEndsAt;
  if (endsAt == null) {
    return 'Access will remain unavailable until a community administrator reactivates your account.';
  }
  final formatted = DateFormat('EEEE, d MMMM yyyy • h:mm a').format(endsAt);
  return 'You can use Jirani again after $formatted.';
}
