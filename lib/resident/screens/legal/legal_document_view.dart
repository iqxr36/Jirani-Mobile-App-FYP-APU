import 'package:flutter/material.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

enum JiraniLegalDocument { termsOfService, communityGuidelines }

class JiraniLegalDocumentView extends StatelessWidget {
  const JiraniLegalDocumentView({super.key, required this.document});

  final JiraniLegalDocument document;

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(document);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return JiraniBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Text(content.title),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(content.icon, color: scheme.primary, size: 36),
                        const SizedBox(height: 14),
                        Text(
                          content.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.introduction,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                height: 1.55,
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        for (final section in content.sections) ...[
                          Text(
                            section.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            section.body,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.65),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalContent {
  const _LegalContent({
    required this.title,
    required this.icon,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final String introduction;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

_LegalContent _contentFor(JiraniLegalDocument document) {
  return switch (document) {
    JiraniLegalDocument.termsOfService => _termsOfService,
    JiraniLegalDocument.communityGuidelines => _communityGuidelines,
  };
}

const _termsOfService = _LegalContent(
  title: 'Terms of Service',
  icon: Icons.description_outlined,
  introduction:
      'These terms explain the rules for using Jirani. By creating an account or continuing to use the platform, you agree to follow these terms and the Community Guidelines.',
  sections: [
    _LegalSection(
      '1. Account eligibility and accuracy',
      'You must provide accurate account, contact, community, and residence information. Keep your sign-in details secure and do not allow another person to use your account. Jirani may require email, phone, location, or residency verification before protected features become available.',
    ),
    _LegalSection(
      '2. Community access',
      'Jirani is designed for verified residents of participating communities. You may only access community content and residents that the system authorises for your selected community. Changing community may require verification to be completed again.',
    ),
    _LegalSection(
      '3. Listings and services',
      'Information about items and services must be truthful, current, lawful, and sufficiently detailed. You are responsible for the condition, availability, pricing, handover, and safe use of anything you list, borrow, lend, request, or provide.',
    ),
    _LegalSection(
      '4. Transactions and payments',
      'Users must honour confirmed arrangements, payment obligations, deposits, return conditions, and completion steps shown in the application. Do not move a transaction outside Jirani to avoid safety controls, records, or agreed charges.',
    ),
    _LegalSection(
      '5. Safety and personal responsibility',
      'Use reasonable care when meeting another resident, sharing property, or providing a service. Jirani supports discovery, communication, and transaction records, but users remain responsible for their choices, property, conduct, and compliance with applicable laws.',
    ),
    _LegalSection(
      '6. Moderation and account restrictions',
      'Jirani administrators may review reports and restrict, suspend, archive, or remove accounts, listings, messages, or content that breach these terms, the Community Guidelines, community rules, or safety requirements. A suspension notice may show the reason and when access is expected to return.',
    ),
    _LegalSection(
      '7. Privacy and platform data',
      'Jirani processes profile, verification, community, transaction, message, report, and technical information to operate and protect the platform. Only share information that is necessary, and do not copy or misuse another resident’s private information.',
    ),
    _LegalSection(
      '8. Availability and changes',
      'Features may be updated, interrupted, or withdrawn for maintenance, security, legal, or operational reasons. These terms may also be updated as Jirani changes. Continued use after an updated version is presented means you accept the revised terms.',
    ),
    _LegalSection(
      '9. Questions and support',
      'If you have questions about these terms, a transaction, or an account decision, use Jirani’s available support channel or contact your community administrator.',
    ),
  ],
);

const _communityGuidelines = _LegalContent(
  title: 'Community Guidelines',
  icon: Icons.groups_2_outlined,
  introduction:
      'Jirani works best when neighbours communicate honestly, protect one another’s privacy, and treat shared community spaces and property with care.',
  sections: [
    _LegalSection(
      '1. Be respectful',
      'Communicate politely. Harassment, threats, hate speech, discrimination, bullying, sexual misconduct, and repeated unwanted contact are not allowed.',
    ),
    _LegalSection(
      '2. Be honest',
      'Use your real information and describe listings, prices, availability, experience, and item condition accurately. Do not impersonate another person, manipulate reviews, or make misleading claims.',
    ),
    _LegalSection(
      '3. Keep transactions safe',
      'Agree on the price, timing, location, condition, and handover details before proceeding. Inspect items appropriately, follow the in-app completion process, and never pressure another resident into an unsafe arrangement.',
    ),
    _LegalSection(
      '4. Protect privacy',
      'Do not publish another person’s address, unit number, documents, phone number, private messages, or other personal information without permission. Verification documents must only be used for authorised review.',
    ),
    _LegalSection(
      '5. Keep content appropriate',
      'Do not post illegal, stolen, dangerous, counterfeit, explicit, fraudulent, or prohibited items or services. Spam, unrelated advertising, malicious links, and attempts to bypass Jirani’s safeguards are not allowed.',
    ),
    _LegalSection(
      '6. Care for borrowed property',
      'Return borrowed items on time and in the agreed condition. Report damage, delays, missing items, or service problems promptly and work honestly toward a fair resolution.',
    ),
    _LegalSection(
      '7. Report concerns responsibly',
      'Use reporting tools for genuine safety, fraud, harassment, transaction, or policy concerns. Include accurate information and relevant evidence. False or retaliatory reports may lead to account action.',
    ),
    _LegalSection(
      '8. Enforcement',
      'Depending on severity and history, Jirani may issue a warning, remove content, limit features, suspend access for a selected period, archive an account, or permanently restrict use. Serious safety or legal concerns may be referred to the appropriate authorities.',
    ),
  ],
);
