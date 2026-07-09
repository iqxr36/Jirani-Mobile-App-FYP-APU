part of '../admin_reports_screen.dart';

class _AdminReportCaseFile extends StatelessWidget {
  const _AdminReportCaseFile({
    required this.report,
    required this.row,
    required this.request,
    required this.evidenceUrls,
    required this.evidenceItems,
    required this.errorMessage,
    required this.isLoading,
    required this.canResolve,
    required this.formatDate,
    required this.onResolveBorrower,
    required this.onResolveLender,
    required this.onDismissReport,
    required this.onIssueWarning,
  });

  final ReportModel report;
  final AdminReportRow row;
  final BorrowRequest? request;
  final List<String> evidenceUrls;
  final List<AdminReportEvidenceItem> evidenceItems;
  final String? errorMessage;
  final bool isLoading;
  final bool canResolve;
  final String Function(DateTime value) formatDate;
  final VoidCallback? onResolveBorrower;
  final VoidCallback? onResolveLender;
  final VoidCallback onDismissReport;
  final VoidCallback onIssueWarning;

  @override
  Widget build(BuildContext context) {
    final disputeRequest = request;
    final isMarketplaceDispute = disputeRequest != null;
    final disputeReason = _bestText(
      [request?.disputeReason, request?.minorIssueReason, row.description],
      fallback: 'No dispute reason was provided.',
    );
    final conductReason = _bestText(
      [row.description],
      fallback: 'No issue details were provided.',
    );
    final deposit = request?.depositAmount ?? 0;
    final deduction = request?.minorDeductionAmount ?? 0;
    final resident = _residentById(
      context.watch<AdminProvider>().residents,
      report.reportedUserId,
    );
    final showPartyMetrics =
        report.reporterId.trim().isNotEmpty &&
        report.reportedUserId.trim().isNotEmpty &&
        report.reporterId != report.reportedUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CaseSummaryBanner(
          title: row.title,
          priority: row.priority,
          status: request?.status ?? report.status,
          depositLabel: 'RM ${deposit.toStringAsFixed(2)}',
          itemTitle: isMarketplaceDispute
              ? disputeRequest.itemTitle
              : adminStatusLabel(report.type),
          showDeposit: isMarketplaceDispute,
        ),
        const SizedBox(height: 16),
        if (disputeRequest != null) ...[
          _PartyComparison(
            borrowerName: disputeRequest.borrowerName,
            borrowerEmail: disputeRequest.borrowerEmail,
            borrowerId: disputeRequest.borrowerId,
            borrowerPhone: disputeRequest.borrowerPhoneNumber,
            borrowerReputationScore: disputeRequest.borrowerReputationScore,
            borrowerVerified: disputeRequest.borrowerVerified,
            lenderName: disputeRequest.ownerName,
            lenderEmail: disputeRequest.ownerEmail,
            lenderId: disputeRequest.ownerId,
          ),
          const SizedBox(height: 16),
          _DisputeProblemCard(
            reason: disputeReason,
            reportedBy: row.reporter,
            reportedAgainst: row.target,
            returnedCondition: disputeRequest.itemConditionAfter,
            ownerNotes: disputeRequest.ownerReturnNotes,
            depositLabel: 'RM ${deposit.toStringAsFixed(2)}',
            deductionLabel: deduction > 0
                ? 'RM ${deduction.toStringAsFixed(2)} requested'
                : 'No partial deduction requested',
            evidenceItems: evidenceItems,
          ),
        ] else ...[
          _ResidentSubjectCard(
            name: row.target,
            userId: report.reportedUserId,
            email: resident?.email ?? '',
            phone: resident?.phoneNumber ?? '',
            trustScore: resident?.communityTrustScore,
            totalReviews: resident?.totalReviews,
            verified: resident?.isVerifiedResident,
            accountFlagged: resident?.accountFlagged,
          ),
          const SizedBox(height: 16),
          _ConductIssueCard(
            reason: conductReason,
            reportedBy: showPartyMetrics ? row.reporter : null,
            reportedAgainst: showPartyMetrics ? row.target : null,
            reportCategory: report.reportCategory,
            reportedMessages: report.reportedMessages,
            evidenceUrls: evidenceUrls,
          ),
        ],
        const SizedBox(height: 16),
        _TransactionFactsCard(
          report: report,
          request: request,
          formatDate: formatDate,
        ),
        const SizedBox(height: 20),
        if (canResolve)
          _ResolutionActions(
            isLoading: isLoading,
            onResolveBorrower: onResolveBorrower,
            onResolveLender: onResolveLender,
          )
        else
          _GeneralReportActions(
            isLoading: isLoading,
            onDismissReport: onDismissReport,
            onIssueWarning: onIssueWarning,
          ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          AdminInlineAlert(message: errorMessage!),
        ],
      ],
    );
  }

  static String _bestText(List<String?> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}

class _CaseSummaryBanner extends StatelessWidget {
  const _CaseSummaryBanner({
    required this.title,
    required this.priority,
    required this.status,
    required this.depositLabel,
    required this.itemTitle,
    this.showDeposit = true,
  });

  final String title;
  final String priority;
  final String status;
  final String depositLabel;
  final String itemTitle;
  final bool showDeposit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.primary.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                if (itemTitle.trim().isNotEmpty)
                  Text(
                    itemTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.muted),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusPill(label: priority, color: AdminColors.danger),
              AdminStatusPill(label: status, color: AdminColors.primary),
              if (showDeposit)
                _MiniMetric(label: 'Deposit held', value: depositLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartyComparison extends StatelessWidget {
  const _PartyComparison({
    required this.borrowerName,
    required this.borrowerEmail,
    required this.borrowerId,
    required this.borrowerPhone,
    required this.borrowerReputationScore,
    required this.borrowerVerified,
    required this.lenderName,
    required this.lenderEmail,
    required this.lenderId,
  });

  final String borrowerName;
  final String borrowerEmail;
  final String borrowerId;
  final String borrowerPhone;
  final double? borrowerReputationScore;
  final bool? borrowerVerified;
  final String lenderName;
  final String lenderEmail;
  final String lenderId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        final cards = [
          _PartyCard(
            role: 'Borrower',
            name: borrowerName,
            email: borrowerEmail,
            id: borrowerId,
            phone: borrowerPhone,
            score: borrowerReputationScore,
            verified: borrowerVerified,
            icon: Icons.person_rounded,
            accent: AdminColors.primary,
          ),
          _PartyCard(
            role: 'Lender',
            name: lenderName,
            email: lenderEmail,
            id: lenderId,
            phone: '',
            score: null,
            verified: null,
            icon: Icons.inventory_2_rounded,
            accent: AdminColors.danger,
          ),
        ];
        if (stacked) {
          return Column(
            children: [
              cards.first,
              const SizedBox(height: 12),
              cards.last,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 12),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.role,
    required this.name,
    required this.email,
    required this.id,
    required this.phone,
    required this.score,
    required this.verified,
    required this.icon,
    required this.accent,
    this.extraFacts = const [],
  });

  final String role;
  final String name;
  final String email;
  final String id;
  final String phone;
  final double? score;
  final bool? verified;
  final IconData icon;
  final Color accent;
  final List<Widget> extraFacts;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Unknown resident' : name.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CompactFact(label: 'User ID', value: id),
          if (email.trim().isNotEmpty) _CompactFact(label: 'Email', value: email),
          if (phone.trim().isNotEmpty) _CompactFact(label: 'Phone', value: phone),
          if (score != null)
            _CompactFact(
              label: 'Trust score',
              value: '${score!.toStringAsFixed(1)} / 5',
            ),
          if (verified != null)
            _CompactFact(
              label: 'Verification',
              value: verified! ? 'Verified resident' : 'Not verified',
            ),
          ...extraFacts,
        ],
      ),
    );
  }
}

class _ResidentSubjectCard extends StatelessWidget {
  const _ResidentSubjectCard({
    required this.name,
    required this.userId,
    required this.email,
    required this.phone,
    required this.trustScore,
    required this.totalReviews,
    required this.verified,
    required this.accountFlagged,
  });

  final String name;
  final String userId;
  final String email;
  final String phone;
  final double? trustScore;
  final int? totalReviews;
  final bool? verified;
  final bool? accountFlagged;

  @override
  Widget build(BuildContext context) {
    return _PartyCard(
      role: 'Resident',
      name: name,
      email: email,
      id: userId,
      phone: phone,
      score: trustScore != null && trustScore! > 0 ? trustScore : null,
      verified: verified,
      icon: Icons.person_rounded,
      accent: AdminColors.primary,
      extraFacts: [
        if (totalReviews != null)
          _CompactFact(
            label: 'Published reviews',
            value: totalReviews.toString(),
          ),
        if (accountFlagged == true)
          const _CompactFact(label: 'Account status', value: 'Flagged'),
      ],
    );
  }
}

class _ConductIssueCard extends StatelessWidget {
  const _ConductIssueCard({
    required this.reason,
    required this.reportedBy,
    required this.reportedAgainst,
    required this.reportCategory,
    required this.reportedMessages,
    required this.evidenceUrls,
  });

  final String reason;
  final String? reportedBy;
  final String? reportedAgainst;
  final String reportCategory;
  final List<ReportedChatMessageSnapshot> reportedMessages;
  final List<String> evidenceUrls;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Row(
                children: const [
                  Icon(Icons.report_rounded, color: AdminColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Issue Details',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
              final proofButton = AdminReportEvidencePreview(
                imageUrls: evidenceUrls,
              );
              if (constraints.maxWidth < 460) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (evidenceUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      proofButton,
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  if (evidenceUrls.isNotEmpty) proofButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (reportCategory.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MiniMetric(
                label: 'Category',
                value: chatReportCategoryLabel(reportCategory),
              ),
            ),
          Text(
            reason,
            style: const TextStyle(
              color: AdminColors.ink,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (reportedMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Quoted messages',
              style: TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final message in reportedMessages)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuotedChatMessageCard(message: message),
              ),
          ],
          if (reportedBy != null && reportedAgainst != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniMetric(label: 'Reported by', value: reportedBy!),
                _MiniMetric(label: 'Against', value: reportedAgainst!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuotedChatMessageCard extends StatelessWidget {
  const _QuotedChatMessageCard({required this.message});

  final ReportedChatMessageSnapshot message;

  @override
  Widget build(BuildContext context) {
    final month = message.sentAt.month.toString().padLeft(2, '0');
    final day = message.sentAt.day.toString().padLeft(2, '0');
    final hour = message.sentAt.hour.toString().padLeft(2, '0');
    final minute = message.sentAt.minute.toString().padLeft(2, '0');
    final timestamp =
        '${message.sentAt.year}-$month-$day $hour:$minute';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${message.senderName} • $timestamp',
            style: const TextStyle(
              color: AdminColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.displayBody,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeProblemCard extends StatelessWidget {
  const _DisputeProblemCard({
    required this.reason,
    required this.reportedBy,
    required this.reportedAgainst,
    required this.returnedCondition,
    required this.ownerNotes,
    required this.depositLabel,
    required this.deductionLabel,
    required this.evidenceItems,
  });

  final String reason;
  final String reportedBy;
  final String reportedAgainst;
  final String returnedCondition;
  final String ownerNotes;
  final String depositLabel;
  final String deductionLabel;
  final List<AdminReportEvidenceItem> evidenceItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Row(
                children: const [
                  Icon(Icons.balance_rounded, color: AdminColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Problem Between Them',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
              final proofButton = AdminReportEvidencePreview(
                evidenceItems: evidenceItems,
              );
              if (constraints.maxWidth < 460) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (evidenceItems.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      proofButton,
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  proofButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: const TextStyle(
              color: AdminColors.ink,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniMetric(label: 'Reported by', value: reportedBy),
              _MiniMetric(label: 'Against', value: reportedAgainst),
              _MiniMetric(label: 'Deposit', value: depositLabel),
              _MiniMetric(label: 'Deduction', value: deductionLabel),
              if (returnedCondition.trim().isNotEmpty)
                _MiniMetric(label: 'Returned condition', value: returnedCondition),
            ],
          ),
          if (ownerNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _NotesBlock(title: 'Lender notes', body: ownerNotes),
          ],
        ],
      ),
    );
  }
}

class _TransactionFactsCard extends StatelessWidget {
  const _TransactionFactsCard({
    required this.report,
    required this.request,
    required this.formatDate,
  });

  final ReportModel report;
  final BorrowRequest? request;
  final String Function(DateTime value) formatDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(AdminColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Case Details',
            style: TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (request != null) ...[
            _CompactFact(label: 'Transaction ID', value: request!.id),
            _CompactFact(label: 'Item ID', value: request!.itemId),
            _CompactFact(label: 'Item', value: request!.itemTitle),
            _CompactFact(
              label: 'Request status',
              value: borrowRequestStatusLabel(request!.status),
            ),
            _CompactFact(
              label: 'Deposit decision',
              value: depositDecisionLabel(request!.depositDecision),
            ),
            if (request!.adminResolution.trim().isNotEmpty)
              _CompactFact(
                label: 'Admin resolution',
                value: adminResolutionLabel(request!.adminResolution),
              ),
          ],
          _CompactFact(label: 'Report ID', value: report.id),
          if (report.chatId.trim().isNotEmpty)
            _CompactFact(label: 'Chat ID', value: report.chatId),
          if (report.reportCategory.trim().isNotEmpty)
            _CompactFact(
              label: 'Report category',
              value: chatReportCategoryLabel(report.reportCategory),
            ),
          _CompactFact(label: 'Report type', value: reportTypeLabel(report.type)),
          _CompactFact(
            label: 'Report status',
            value: reportStatusLabel(report.status),
          ),
          _CompactFact(label: 'Created', value: formatDate(report.createdAt)),
          _CompactFact(label: 'Updated', value: formatDate(report.updatedAt)),
        ],
      ),
    );
  }
}

class _ResolutionActions extends StatelessWidget {
  const _ResolutionActions({
    required this.isLoading,
    required this.onResolveBorrower,
    required this.onResolveLender,
  });

  final bool isLoading;
  final VoidCallback? onResolveBorrower;
  final VoidCallback? onResolveLender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: isLoading ? null : onResolveBorrower,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Resolve for Borrower'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: isLoading ? null : onResolveLender,
            icon: const Icon(Icons.gavel_rounded),
            label: const Text('Resolve for Lender'),
          ),
        ],
      ),
    );
  }
}

class _GeneralReportActions extends StatelessWidget {
  const _GeneralReportActions({
    required this.isLoading,
    required this.onDismissReport,
    required this.onIssueWarning,
  });

  final bool isLoading;
  final VoidCallback onDismissReport;
  final VoidCallback onIssueWarning;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : onDismissReport,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Dismiss Report'),
        ),
        FilledButton.tonalIcon(
          onPressed: isLoading ? null : onIssueWarning,
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Issue Warning'),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFact extends StatelessWidget {
  const _CompactFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              displayValue,
              style: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AdminColors.ink)),
        ],
      ),
    );
  }
}
