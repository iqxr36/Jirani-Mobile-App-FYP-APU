// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_overview_screen.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Sunday,14-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:provider/provider.dart';

// Admin overview UI feature: shows operational statistics and recent activity for the admin scope.
class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = _OverviewStats.from(admin);

    return AdminPageScroll(
      children: [
        const AdminCommunityScopeBanner(),
        const SizedBox(height: 20),
        _CommandCenterSummary(stats: stats),
        const SizedBox(height: 20),
        AdminResponsiveGrid(
          minTileWidth: 220,
          children: [
            AdminKpiCard(
              title: 'Total Residents',
              value: stats.totalResidents.toString(),
              detail: '${stats.verifiedResidents} verified residents',
              icon: Icons.groups_2_rounded,
              color: AdminColors.primary,
            ),
            AdminKpiCard(
              title: 'Pending Verifications',
              value: stats.pendingVerifications.toString(),
              detail: stats.pendingVerifications == 0
                  ? 'Queue is clear'
                  : 'Awaiting admin review',
              icon: Icons.how_to_reg_rounded,
              color: const Color(0xFF0E9384),
            ),
            AdminKpiCard(
              title: 'Active Listings',
              value: stats.activeListings.toString(),
              detail: '${stats.totalListingPosts} total marketplace posts',
              icon: Icons.storefront_rounded,
              color: const Color(0xFF2563EB),
            ),
            AdminKpiCard(
              title: 'Open Reports',
              value: stats.openReports.toString(),
              detail: stats.openReports == 0
                  ? 'No active escalations'
                  : 'Reports requiring review',
              icon: Icons.report_problem_rounded,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChartGallery(stats: stats),
        const SizedBox(height: 20),
        _StatisticsLayout(stats: stats),
      ],
    );
  }
}

class _CommandCenterSummary extends StatelessWidget {
  const _CommandCenterSummary({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF062A3A), Color(0xFF0F766E), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                stats.summaryLine,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

          final pills = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(
                label: 'Clearance',
                value: '${stats.verificationRatePercent}%',
                icon: Icons.verified_rounded,
              ),
              _SummaryPill(
                label: 'Risk queue',
                value: stats.riskQueue.toString(),
                icon: Icons.shield_rounded,
              ),
              _SummaryPill(
                label: 'Live workload',
                value: stats.liveWorkload.toString(),
                icon: Icons.bolt_rounded,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [headline, const SizedBox(height: 18), pills],
            );
          }

          return Row(
            children: [
              Expanded(child: headline),
              const SizedBox(width: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: pills,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGallery extends StatelessWidget {
  const _ChartGallery({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminResponsiveGrid(
      minTileWidth: 280,
      mainAxisExtent: 330,
      children: [
        _ChartCard(
          title: 'Verification Mix',
          subtitle: '${stats.verificationRatePercent}% verified',
          child: _DonutChart(
            centerValue: stats.totalResidents.toString(),
            centerLabel: 'residents',
            slices: [
              _ChartSlice(
                label: 'Verified',
                value: stats.verifiedResidents,
                color: AdminColors.success,
              ),
              _ChartSlice(
                label: 'Pending',
                value: stats.pendingVerifications,
                color: AdminColors.warning,
              ),
              _ChartSlice(
                label: 'Rejected',
                value: stats.rejectedRequests,
                color: AdminColors.accent,
              ),
            ],
          ),
        ),
        _ChartCard(
          title: 'Workload Shape',
          subtitle: '${stats.liveWorkload} live work items',
          child: _BarChart(
            bars: [
              _ChartBar(
                label: 'Items',
                value: stats.activeItemListings,
                color: const Color(0xFF2563EB),
              ),
              _ChartBar(
                label: 'Services',
                value: stats.activeServiceListings,
                color: const Color(0xFF0E9384),
              ),
              _ChartBar(
                label: 'Borrow',
                value: stats.activeBorrowTransactions,
                color: const Color(0xFF7C3AED),
              ),
              _ChartBar(
                label: 'Jobs',
                value: stats.activeServiceRequests,
                color: const Color(0xFFF97316),
              ),
            ],
          ),
        ),
        _ChartCard(
          title: 'Risk Breakdown',
          subtitle: stats.riskQueue == 0 ? 'No active risk' : 'Needs review',
          child: _RiskBreakdownChart(
            bars: [
              _ChartBar(
                label: 'Reports',
                value: stats.openReports,
                color: const Color(0xFFDC2626),
              ),
              _ChartBar(
                label: 'Borrow',
                value: stats.disputedBorrowTransactions,
                color: const Color(0xFF7C3AED),
              ),
              _ChartBar(
                label: 'Services',
                value: stats.disputedServiceRequests,
                color: const Color(0xFFF97316),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminSurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
  });

  final List<_ChartSlice> slices;
  final String centerValue;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 124,
              height: 124,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(124),
                    painter: _DonutChartPainter(slices: slices),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerValue,
                        style: const TextStyle(
                          color: AdminColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        centerLabel,
                        style: const TextStyle(
                          color: AdminColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 96,
          child: _ChartLegend(
            entries: [
              for (final slice in slices)
                _ChartLegendEntry(
                  color: slice.color,
                  label: slice.label,
                  value: slice.value.toString(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars});

  final List<_ChartBar> bars;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _BarChartPainter(bars: bars),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final bar in bars)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      bar.value.toString(),
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bar.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RiskBreakdownChart extends StatelessWidget {
  const _RiskBreakdownChart({required this.bars});

  final List<_ChartBar> bars;

  @override
  Widget build(BuildContext context) {
    final total = bars.fold<int>(0, (sum, bar) => sum + bar.value);
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _RiskBarsPainter(bars: bars),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.background.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toString(),
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'risk items',
                      style: TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ChartLegend(
          columns: 3,
          entries: [
            for (final bar in bars)
              _ChartLegendEntry(
                color: bar.color,
                label: bar.label,
                value: bar.value.toString(),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.entries, this.columns = 1});

  final List<_ChartLegendEntry> entries;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final entry in entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: entry.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              entry.value,
              style: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
    ];

    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (final child in children) Expanded(child: child),
      ],
    );
  }
}

class _StatisticsLayout extends StatelessWidget {
  const _StatisticsLayout({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = JiraniResponsive.isAdminWide(constraints.maxWidth);
        final left = Column(
          children: [
            _VerificationPipelinePanel(stats: stats),
            const SizedBox(height: 20),
            _MarketplaceMixPanel(stats: stats),
          ],
        );
        final right = Column(
          children: [
            _RiskQueuePanel(stats: stats),
            const SizedBox(height: 20),
            AdminPanel(
              title: 'Recent Activity',
              action: '${stats.recentActivityCount} live signals',
              child: const AdminRecentActivityList(),
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: left),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 20), right]);
      },
    );
  }
}

class _VerificationPipelinePanel extends StatelessWidget {
  const _VerificationPipelinePanel({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Verification Pipeline',
      action: '${stats.verificationRatePercent}% cleared',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StackedMeter(
            segments: [
              _MeterSegment(
                value: stats.verifiedResidents,
                color: AdminColors.success,
                label: 'Verified',
              ),
              _MeterSegment(
                value: stats.pendingVerifications,
                color: AdminColors.warning,
                label: 'Pending',
              ),
              _MeterSegment(
                value: stats.rejectedRequests,
                color: AdminColors.accent,
                label: 'Rejected',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatisticRows(
            rows: [
              _StatisticRowData(
                label: 'Verified residents',
                value: stats.verifiedResidents.toString(),
                icon: Icons.verified_user_rounded,
                color: AdminColors.success,
              ),
              _StatisticRowData(
                label: 'Waiting for review',
                value: stats.pendingVerifications.toString(),
                icon: Icons.pending_actions_rounded,
                color: AdminColors.warning,
              ),
              _StatisticRowData(
                label: 'Rejected requests',
                value: stats.rejectedRequests.toString(),
                icon: Icons.block_rounded,
                color: AdminColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketplaceMixPanel extends StatelessWidget {
  const _MarketplaceMixPanel({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      stats.activeItemListings,
      stats.activeServiceListings,
      stats.activeBorrowTransactions,
      stats.activeServiceRequests,
    ].fold<int>(1, (max, value) => value > max ? value : max);

    return AdminPanel(
      title: 'Marketplace & Services',
      action: '${stats.totalTransactions} transactions',
      child: Column(
        children: [
          _ProgressStatBar(
            label: 'Items available',
            value: stats.activeItemListings,
            maxValue: maxValue,
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 14),
          _ProgressStatBar(
            label: 'Services active',
            value: stats.activeServiceListings,
            maxValue: maxValue,
            icon: Icons.design_services_rounded,
            color: const Color(0xFF0E9384),
          ),
          const SizedBox(height: 14),
          _ProgressStatBar(
            label: 'Borrow flows live',
            value: stats.activeBorrowTransactions,
            maxValue: maxValue,
            icon: Icons.sync_alt_rounded,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 14),
          _ProgressStatBar(
            label: 'Service jobs live',
            value: stats.activeServiceRequests,
            maxValue: maxValue,
            icon: Icons.handyman_rounded,
            color: const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }
}

class _RiskQueuePanel extends StatelessWidget {
  const _RiskQueuePanel({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Risk Queue',
      action: stats.riskQueue == 0 ? 'clear' : '${stats.riskQueue} items',
      child: Column(
        children: [
          _RiskScoreDial(stats: stats),
          const SizedBox(height: 18),
          _StatisticRows(
            rows: [
              _StatisticRowData(
                label: 'Open reports',
                value: stats.openReports.toString(),
                icon: Icons.report_problem_rounded,
                color: const Color(0xFFDC2626),
              ),
              _StatisticRowData(
                label: 'Borrow disputes',
                value: stats.disputedBorrowTransactions.toString(),
                icon: Icons.balance_rounded,
                color: const Color(0xFF7C3AED),
              ),
              _StatisticRowData(
                label: 'Service disputes',
                value: stats.disputedServiceRequests.toString(),
                icon: Icons.support_agent_rounded,
                color: const Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskScoreDial extends StatelessWidget {
  const _RiskScoreDial({required this.stats});

  final _OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    final riskText = stats.riskQueue == 0
        ? 'Stable'
        : stats.riskQueue < 4
        ? 'Watch'
        : 'Priority';
    final color = stats.riskQueue == 0
        ? AdminColors.success
        : stats.riskQueue < 4
        ? AdminColors.warning
        : AdminColors.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (stats.riskQueue / 8).clamp(0.06, 1).toDouble(),
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  color: color,
                ),
                Text(
                  stats.riskQueue.toString(),
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskText,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.riskQueue == 0
                      ? 'No reports or disputes are waiting for admin action.'
                      : 'Reports and disputes need review before they age.',
                  style: const TextStyle(color: AdminColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStatBar extends StatelessWidget {
  const _ProgressStatBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = maxValue <= 0
        ? 0.0
        : (value / maxValue).clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      color: AdminColors.ink,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AdminColors.background,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackedMeter extends StatelessWidget {
  const _StackedMeter({required this.segments});

  final List<_MeterSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    final visibleTotal = total == 0 ? 1 : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                for (final segment in segments)
                  Expanded(
                    flex: segment.value == 0 ? 1 : segment.value,
                    child: Container(
                      color: total == 0
                          ? AdminColors.border
                          : segment.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final segment in segments)
              _MeterLegend(
                color: segment.color,
                label: segment.label,
                value: total == 0
                    ? '0%'
                    : '${(segment.value / visibleTotal * 100).round()}%',
              ),
          ],
        ),
      ],
    );
  }
}

class _MeterLegend extends StatelessWidget {
  const _MeterLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $value',
          style: const TextStyle(
            color: AdminColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatisticRows extends StatelessWidget {
  const _StatisticRows({required this.rows});

  final List<_StatisticRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _StatisticRow(row: rows[i]),
          if (i != rows.length - 1)
            const Divider(height: 18, color: AdminColors.border),
        ],
      ],
    );
  }
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({required this.row});

  final _StatisticRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: row.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(row.icon, color: row.color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.label,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          row.value,
          style: const TextStyle(
            color: AdminColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// Admin overview UI feature: shows recent verification, report, resident, and listing activity.
class AdminRecentActivityList extends StatelessWidget {
  const AdminRecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = <AdminActivityRow>[
      ...admin.verificationRequests.take(4).map((request) {
        return AdminActivityRow(
          icon: Icons.verified_user_rounded,
          title: 'Verification ${adminStatusLabel(request.status)}',
          body: '${request.fullName} from ${request.communityName}',
          time: adminFormatDate(request.submittedAt),
        );
      }),
      ...admin.reports.take(3).map((report) {
        return AdminActivityRow(
          icon: Icons.report_problem_rounded,
          title: report.title.isEmpty ? 'Report opened' : report.title,
          body: report.description,
          time: adminFormatDate(report.createdAt),
        );
      }),
      ...admin.listings.take(3).map((listing) {
        return AdminActivityRow(
          icon: Icons.storefront_rounded,
          title: 'Listing ${adminStatusLabel(listing.status)}',
          body: '${listing.title} by ${listing.ownerName}',
          time: adminFormatDate(listing.createdAt),
        );
      }),
      ...admin.serviceRequests.take(2).map((request) {
        return AdminActivityRow(
          icon: Icons.handyman_rounded,
          title: 'Service ${adminStatusLabel(request.status)}',
          body: '${request.serviceTitle} for ${request.requesterName}',
          time: adminFormatDate(request.createdAt),
        );
      }),
    ].take(7).toList();

    if (items.isEmpty) {
      return const AdminEmptyPanelMessage(
        icon: Icons.history_rounded,
        title: 'No recent activity',
        body: 'Verification requests, listings, and reports will appear here.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _ActivityTile(item: items[i]),
          if (i != items.length - 1)
            const Divider(height: 18, color: AdminColors.border),
        ],
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final AdminActivityRow item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AdminColors.secondary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: AdminColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.time,
          style: const TextStyle(
            color: AdminColors.muted,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _OverviewStats {
  const _OverviewStats({
    required this.totalResidents,
    required this.verifiedResidents,
    required this.pendingVerifications,
    required this.rejectedRequests,
    required this.activeItemListings,
    required this.activeServiceListings,
    required this.totalListingPosts,
    required this.openReports,
    required this.disputedBorrowTransactions,
    required this.disputedServiceRequests,
    required this.activeBorrowTransactions,
    required this.activeServiceRequests,
    required this.totalTransactions,
    required this.recentActivityCount,
  });

  final int totalResidents;
  final int verifiedResidents;
  final int pendingVerifications;
  final int rejectedRequests;
  final int activeItemListings;
  final int activeServiceListings;
  final int totalListingPosts;
  final int openReports;
  final int disputedBorrowTransactions;
  final int disputedServiceRequests;
  final int activeBorrowTransactions;
  final int activeServiceRequests;
  final int totalTransactions;
  final int recentActivityCount;

  int get activeListings => activeItemListings + activeServiceListings;
  int get riskQueue =>
      openReports + disputedBorrowTransactions + disputedServiceRequests;
  int get liveWorkload =>
      pendingVerifications + activeBorrowTransactions + activeServiceRequests;

  int get verificationRatePercent {
    if (totalResidents == 0) return 0;
    return (verifiedResidents / totalResidents * 100).round().clamp(0, 100);
  }

  String get summaryLine {
    if (riskQueue == 0 && pendingVerifications == 0) {
      return 'Your community operations are clear: no open risk items and no pending verification queue.';
    }
    return '$pendingVerifications verification requests, $riskQueue risk items, and $liveWorkload live work items need visibility today.';
  }

  factory _OverviewStats.from(AdminProvider admin) {
    final stats = admin.dashboardStats;
    final activeItemListings = admin.listings
        .where((item) => item.status == AppConstants.itemStatusAvailable)
        .length;
    final activeServiceListings = admin.services
        .where((service) => service.status == AppConstants.serviceStatusActive)
        .length;
    final disputedBorrowTransactions = admin.borrowRequests
        .where((request) => request.status == AppConstants.borrowStatusDisputed)
        .length;
    final disputedServiceRequests = admin.serviceRequests
        .where(
          (request) =>
              request.status == AppConstants.serviceRequestStatusDisputed,
        )
        .length;
    final activeBorrowTransactions = admin.borrowRequests
        .where((request) => _activeBorrowStatuses.contains(request.status))
        .length;
    final activeServiceRequests = admin.serviceRequests
        .where((request) => _activeServiceRequestStatuses.contains(request.status))
        .length;

    return _OverviewStats(
      totalResidents: stats['totalUsers'] ?? admin.residents.length,
      verifiedResidents: stats['verifiedResidents'] ?? 0,
      pendingVerifications:
          stats['submittedRequests'] ?? admin.verificationRequests.length,
      rejectedRequests: stats['rejectedRequests'] ?? 0,
      activeItemListings: activeItemListings,
      activeServiceListings: activeServiceListings,
      totalListingPosts: admin.listings.length + admin.services.length,
      openReports: stats['openReports'] ?? admin.reports.length,
      disputedBorrowTransactions: disputedBorrowTransactions,
      disputedServiceRequests: disputedServiceRequests,
      activeBorrowTransactions: activeBorrowTransactions,
      activeServiceRequests: activeServiceRequests,
      totalTransactions: admin.borrowRequests.length + admin.serviceRequests.length,
      recentActivityCount:
          admin.verificationRequests.length +
          admin.reports.length +
          admin.listings.length +
          admin.serviceRequests.length,
    );
  }

  static const Set<String> _activeBorrowStatuses = {
    AppConstants.borrowStatusApproved,
    AppConstants.borrowStatusPickupReady,
    AppConstants.borrowStatusHandedOver,
    AppConstants.borrowStatusActive,
    AppConstants.borrowStatusReturnSubmitted,
    AppConstants.borrowStatusMinorIssuePending,
    AppConstants.borrowStatusDisputed,
  };

  static const Set<String> _activeServiceRequestStatuses = {
    AppConstants.serviceRequestStatusAccepted,
    AppConstants.serviceRequestStatusAcceptedAwaitingPayment,
    AppConstants.serviceRequestStatusPaidHeld,
    AppConstants.serviceRequestStatusInProgress,
    AppConstants.serviceRequestStatusCompletedPayoutPending,
    AppConstants.serviceRequestStatusDisputed,
  };
}

class _MeterSegment {
  const _MeterSegment({
    required this.value,
    required this.color,
    required this.label,
  });

  final int value;
  final Color color;
  final String label;
}

class _StatisticRowData {
  const _StatisticRowData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ChartSlice {
  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ChartBar {
  const _ChartBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ChartLegendEntry {
  const _ChartLegendEntry({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.slices});

  final List<_ChartSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - 14;
    final strokeWidth = 18.0;
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final backgroundPaint = Paint()
      ..color = AdminColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    const gap = 0.035;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total * math.pi * 2) - gap;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.max(0.01, sweep),
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.bars});

  final List<_ChartBar> bars;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = bars.fold<int>(1, (max, bar) {
      return bar.value > max ? bar.value : max;
    });
    final gridPaint = Paint()
      ..color = AdminColors.border
      ..strokeWidth = 1;
    final baseline = size.height - 6;

    for (var i = 0; i < 4; i++) {
      final y = baseline - (baseline * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final slotWidth = size.width / bars.length;
    final barWidth = math.min(34.0, slotWidth * 0.44);
    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final barHeight = baseline * (bar.value / maxValue);
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final top = baseline - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, math.max(6.0, barHeight)),
        const Radius.circular(8),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            bar.color,
            bar.color.withValues(alpha: 0.54),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.bars != bars;
  }
}

class _RiskBarsPainter extends CustomPainter {
  const _RiskBarsPainter({required this.bars});

  final List<_ChartBar> bars;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    final maxValue = bars.fold<int>(1, (max, bar) {
      return bar.value > max ? bar.value : max;
    });
    final guidePaint = Paint()
      ..color = AdminColors.border.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, guidePaint);
    canvas.drawCircle(center, radius * 0.62, guidePaint);

    final total = bars.fold<int>(0, (sum, bar) => sum + bar.value);
    if (total <= 0) return;

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final angle = -math.pi / 2 + i * math.pi * 2 / bars.length;
      final length = radius * (0.28 + 0.72 * (bar.value / maxValue));
      final end = Offset(
        center.dx + math.cos(angle) * length,
        center.dy + math.sin(angle) * length,
      );
      final paint = Paint()
        ..color = bar.color
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, end, paint);
      canvas.drawCircle(end, 6, Paint()..color = Colors.white);
      canvas.drawCircle(end, 4, Paint()..color = bar.color);
    }
  }

  @override
  bool shouldRepaint(covariant _RiskBarsPainter oldDelegate) {
    return oldDelegate.bars != bars;
  }
}
