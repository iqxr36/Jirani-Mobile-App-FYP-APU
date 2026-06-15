import 'package:flutter/material.dart';
import 'package:jirani/admin/models/admin_display_rows.dart';
import 'package:jirani/admin/theme/admin_colors.dart';
import 'package:jirani/admin/utils/admin_formatters.dart';
import 'package:jirani/admin/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/widgets/admin_status_widgets.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.dashboardStats;
    final requests = admin.verificationRequests;
    final totalUsers = stats['totalUsers'] ?? 0;
    final submitted = stats['submittedRequests'] ?? requests.length;
    final verified = stats['verifiedResidents'] ?? 0;
    final activeListings = stats['activeListings'] ?? admin.listings.length;
    final openReports = stats['openReports'] ?? admin.reports.length;

    return AdminPageScroll(
      children: [
        const AdminCommunityScopeBanner(),
        const SizedBox(height: 20),
        AdminResponsiveGrid(
          minTileWidth: 220,
          children: [
            AdminKpiCard(
              title: 'Total Residents',
              value: totalUsers.toString(),
              detail: '$verified verified residents',
              icon: Icons.groups_2_rounded,
              color: AdminColors.primary,
            ),
            AdminKpiCard(
              title: 'Pending Verifications',
              value: submitted.toString(),
              detail: 'Awaiting admin review',
              icon: Icons.how_to_reg_rounded,
              color: AdminColors.secondary,
            ),
            AdminKpiCard(
              title: 'Active Listings',
              value: activeListings.toString(),
              detail: '${admin.listings.length} total listings',
              icon: Icons.storefront_rounded,
              color: AdminColors.success,
            ),
            AdminKpiCard(
              title: 'Open Reports',
              value: openReports.toString(),
              detail: 'Reports requiring review',
              icon: Icons.report_problem_rounded,
              color: AdminColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = JiraniResponsive.isAdminWide(constraints.maxWidth);
            final chart = AdminPanel(
              title: 'User Growth',
              action: 'Last 6 months',
              child: SizedBox(
                height: 280,
                child: CustomPaint(
                  painter: AdminLineChartPainter(
                    values: const [24, 34, 49, 58, 72, 91],
                  ),
                  child: const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        'Jan   Feb   Mar   Apr   May   Jun',
                        style: TextStyle(
                          color: AdminColors.muted,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final activity = AdminPanel(
              title: 'Recent Activity',
              action: '${requests.length} live requests',
              child: const AdminRecentActivityList(),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: activity),
                ],
              );
            }
            return Column(
              children: [chart, const SizedBox(height: 20), activity],
            );
          },
        ),
      ],
    );
  }
}

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
      ...admin.listings.take(3).map((listing) {
        return AdminActivityRow(
          icon: Icons.storefront_rounded,
          title: 'Listing ${adminStatusLabel(listing.status)}',
          body: '${listing.title} by ${listing.ownerName}',
          time: adminFormatDate(listing.createdAt),
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
    ].take(6).toList();

    if (items.isEmpty) {
      return const AdminEmptyPanelMessage(
        icon: Icons.history_rounded,
        title: 'No recent activity',
        body: 'Verification requests, listings, and reports will appear here.',
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: const TextStyle(color: AdminColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AdminLineChartPainter extends CustomPainter {
  const AdminLineChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = AdminColors.border
      ..strokeWidth = 1;
    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [
          AdminColors.secondary.withValues(alpha: 0.28),
          AdminColors.secondary.withValues(alpha: 0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    final paintLine = Paint()
      ..color = AdminColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = AdminColors.primary;

    final chartHeight = size.height - 28;
    for (var i = 0; i < 5; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1 : max - min;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y =
          chartHeight - ((values[i] - min) / range * (chartHeight - 18)) - 8;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant AdminLineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
