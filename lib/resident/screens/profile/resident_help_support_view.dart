// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_help_support_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_support_contact.dart';
import 'package:jirani/shared/services/community_support_contact_service.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

typedef SupportUriLauncher = Future<bool> Function(Uri uri);

/// Resident support feature: exposes the official contact for the resident's community.
class ResidentHelpSupportView extends StatefulWidget {
  const ResidentHelpSupportView({
    super.key,
    this.contactReader,
    this.uriLauncher,
  });

  final CommunitySupportContactReader? contactReader;
  final SupportUriLauncher? uriLauncher;

  @override
  State<ResidentHelpSupportView> createState() =>
      _ResidentHelpSupportViewState();
}

class _ResidentHelpSupportViewState extends State<ResidentHelpSupportView> {
  late final CommunitySupportContactReader _contactReader =
      widget.contactReader ?? CommunitySupportContactService();
  late final SupportUriLauncher _uriLauncher =
      widget.uriLauncher ?? _launchExternalUri;

  CommunitySupportContact? _contact;
  bool _loading = true;
  String? _errorMessage;
  String? _loadedCommunityId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final communityId =
        context.read<AuthViewModel>().currentUser?.communityId.trim() ?? '';
    if (_loadedCommunityId == communityId) return;
    _loadedCommunityId = communityId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadContact());
    });
  }

  static Future<bool> _launchExternalUri(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadContact() async {
    final communityId = _loadedCommunityId ?? '';
    if (communityId.isEmpty) {
      setState(() {
        _contact = null;
        _loading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final contact = await _contactReader.fetchForCommunity(communityId);
      if (!mounted || communityId != _loadedCommunityId) return;
      setState(() => _contact = contact);
    } catch (_) {
      if (!mounted || communityId != _loadedCommunityId) return;
      setState(() {
        _contact = null;
        _errorMessage =
            'We could not load your community support contact. Check your connection and try again.';
      });
    } finally {
      if (mounted && communityId == _loadedCommunityId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _emailAdministrator(AppUser user) async {
    final contact = _contact;
    if (contact == null) return;
    final communityName = user.communityName.trim().isEmpty
        ? 'My Community'
        : user.communityName.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: contact.email,
      queryParameters: <String, String>{
        'subject': 'Jirani Support Request - $communityName',
        'body':
            'Hello ${contact.contactName},\n\nI am ${user.fullName}, a resident of $communityName.\n\nI need help with:\n',
      },
    );
    await _openUri(
      uri,
      failureMessage:
          'No email app could be opened. You can copy the email address shown above.',
    );
  }

  Future<void> _callAdministrator() async {
    final contact = _contact;
    if (contact == null) return;
    await _openUri(
      Uri(scheme: 'tel', path: contact.phoneNumber),
      failureMessage:
          'Calling is not available on this device. You can copy the phone number shown above.',
    );
  }

  Future<void> _openUri(
    Uri uri, {
    required String failureMessage,
  }) async {
    var opened = false;
    try {
      opened = await _uriLauncher(uri);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                    _SupportHeader(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 18),
                    if (_loading)
                      const _SupportStateCard.loading()
                    else if (user == null ||
                        (user.communityId.trim().isEmpty))
                      const _SupportStateCard(
                        icon: Icons.location_city_outlined,
                        title: 'Community not selected',
                        message:
                            'Select your community before contacting its administrator.',
                      )
                    else if (_errorMessage != null)
                      _SupportStateCard(
                        icon: Icons.cloud_off_outlined,
                        title: 'Contact unavailable',
                        message: _errorMessage!,
                        actionLabel: 'Retry',
                        onAction: () => unawaited(_loadContact()),
                      )
                    else if (_contact == null)
                      const _SupportStateCard(
                        icon: Icons.support_agent_rounded,
                        title: 'Contact details not configured',
                        message:
                            'Your community administrator has not published support contact details yet.',
                      )
                    else
                      _SupportContactCard(
                        communityName: user.communityName,
                        contact: _contact!,
                        onEmail: () => unawaited(_emailAdministrator(user)),
                        onCall: () => unawaited(_callAdministrator()),
                      ),
                    const SizedBox(height: 14),
                    const _EmergencyNotice(),
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

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
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
                'Help & Support',
                style: TextStyle(
                  color: _kBrandTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Contact your community administrator',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SupportContactCard extends StatelessWidget {
  const _SupportContactCard({
    required this.communityName,
    required this.contact,
    required this.onEmail,
    required this.onCall,
  });

  final String communityName;
  final CommunitySupportContact contact;
  final VoidCallback onEmail;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0x1A006D77),
            child: Icon(Icons.support_agent_rounded, color: _kBrandTeal),
          ),
          const SizedBox(height: 12),
          Text(
            contact.contactName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            communityName.trim().isEmpty
                ? 'Community Administrator'
                : '$communityName Administrator',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _ContactDetail(
            icon: Icons.email_outlined,
            label: 'Email',
            value: contact.email,
          ),
          const SizedBox(height: 12),
          _ContactDetail(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: contact.phoneNumber,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('email-administrator'),
            onPressed: onEmail,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: _kBrandTeal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Email Administrator'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('call-administrator'),
            onPressed: onCall,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: _kBrandTeal,
              side: const BorderSide(color: _kBrandTeal),
            ),
            icon: const Icon(Icons.phone_outlined),
            label: const Text('Call Administrator'),
          ),
        ],
      ),
    );
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _kBrandTeal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kBrandTeal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportStateCard extends StatelessWidget {
  const _SupportStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  const _SupportStateCard.loading()
    : icon = Icons.support_agent_rounded,
      title = 'Loading support contact',
      message = 'Finding the administrator for your community...',
      actionLabel = null,
      onAction = null;

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          if (title == 'Loading support contact')
            const CircularProgressIndicator(color: _kBrandTeal)
          else
            Icon(icon, size: 36, color: _kBrandTeal),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _EmergencyNotice extends StatelessWidget {
  const _EmergencyNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Community support is not an emergency service. Contact the appropriate local emergency service if anyone is in immediate danger.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
