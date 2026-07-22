import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/admin/screens/dashboard/admin_transactions_screen.dart';
import 'package:jirani/admin/screens/reports/admin_reports_screen.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets(
    'transaction filters combine, include calendar boundary, and preserve queues',
    (tester) async {
      await _setScreenSize(tester, const Size(1600, 1200));
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final provider = _StaticAdminProvider(
        borrowRequests: [
          _borrowRequest(
            id: 'urgent',
            title: 'Urgent Drill',
            status: AppConstants.borrowStatusDisputed,
            createdAt: startOfToday.subtract(const Duration(days: 120)),
            depositDispute: true,
          ),
          _borrowRequest(
            id: 'border',
            title: 'Boundary Ladder',
            status: AppConstants.borrowStatusApproved,
            createdAt: startOfToday.subtract(const Duration(days: 6)),
          ),
        ],
        serviceRequests: [
          _serviceRequest(
            id: 'service',
            status: AppConstants.serviceRequestStatusCompleted,
            createdAt: now,
          ),
        ],
      );
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        _adminHost(provider, const AdminTransactionsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('BR-URGENT'), findsOneWidget);
      expect(find.text('BR-BORDER'), findsOneWidget);
      expect(find.text('SR-SERVIC'), findsOneWidget);

      await _selectDropdownOption(tester, 'Date range', 'Last 7 days');

      expect(find.text('BR-URGENT'), findsNothing);
      expect(find.text('BR-BORDER'), findsOneWidget);
      expect(find.text('SR-SERVIC'), findsOneWidget);
      expect(find.text('Urgent Drill'), findsOneWidget);
      expect(find.text('2 of 3 records'), findsOneWidget);

      await _selectDropdownOption(tester, 'Type', 'Borrow');
      await _selectDropdownOption(tester, 'Status', 'Completed');

      expect(find.text('No matching transactions'), findsOneWidget);
      expect(find.text('0 of 3 records'), findsOneWidget);
      expect(find.text('Urgent Drill'), findsOneWidget);

      await tester.ensureVisible(find.text('Clear filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('BR-URGENT'), findsOneWidget);
      expect(find.text('BR-BORDER'), findsOneWidget);
      expect(find.text('SR-SERVIC'), findsOneWidget);
      expect(find.text('3 records'), findsOneWidget);
      expect(find.text('All time'), findsOneWidget);
      expect(find.text('All types'), findsOneWidget);
      expect(find.text('All statuses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('report priority combines with Open and Completed filters', (
    tester,
  ) async {
    await _setScreenSize(tester, const Size(1600, 1200));
    final now = DateTime.now();
    final provider = _StaticAdminProvider(
      reports: [
        _report(
          id: 'high-open',
          title: 'Damaged bicycle',
          type: AppConstants.reportTypeDamagedItem,
          status: AppConstants.reportStatusOpen,
          createdAt: now,
        ),
        _report(
          id: 'low-open',
          title: 'Other concern',
          type: AppConstants.reportTypeOther,
          status: AppConstants.reportStatusOpen,
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
        _report(
          id: 'medium-completed',
          title: 'Misconduct resolved',
          type: AppConstants.reportTypeUserMisconduct,
          status: AppConstants.reportStatusResolved,
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
      ],
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(_adminHost(provider, const AdminReportsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Damaged bicycle'), findsWidgets);
    expect(find.text('Other concern'), findsWidgets);
    expect(find.text('Misconduct resolved'), findsNothing);

    await _selectDropdownOption(tester, 'Priority', 'Low');

    expect(find.text('Damaged bicycle'), findsNothing);
    expect(find.text('Other concern'), findsWidgets);

    await tester.tap(find.widgetWithText(AdminFilterChipButton, 'Completed'));
    await tester.pumpAndSettle();

    expect(find.text('No low-priority completed reports'), findsOneWidget);
    expect(find.text('Clear priority filter'), findsOneWidget);

    await tester.tap(find.text('Clear priority filter'));
    await tester.pumpAndSettle();

    expect(find.text('All priorities'), findsOneWidget);
    expect(find.text('Misconduct resolved'), findsWidgets);
    expect(find.text('Other concern'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectDropdownOption(
  WidgetTester tester,
  String label,
  String option,
) async {
  final dropdown = find.byKey(ValueKey<String>('admin-filter-$label'));
  expect(dropdown, findsOneWidget);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _setScreenSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _adminHost(AdminProvider provider, Widget child) {
  return ChangeNotifierProvider<AdminProvider>.value(
    value: provider,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

class _StaticAdminProvider extends AdminProvider {
  _StaticAdminProvider({
    this.reports = const [],
    this.borrowRequests = const [],
    this.serviceRequests = const [],
  });

  @override
  final List<ReportModel> reports;

  @override
  final List<BorrowRequest> borrowRequests;

  @override
  final List<ServiceRequestModel> serviceRequests;
}

BorrowRequest _borrowRequest({
  required String id,
  required String title,
  required String status,
  required DateTime createdAt,
  bool depositDispute = false,
}) {
  return BorrowRequest.fromMap(id, {
    'itemTitle': title,
    'ownerName': 'Owner $id',
    'borrowerName': 'Borrower $id',
    'status': status,
    'paymentStatus': depositDispute
        ? AppConstants.paymentStatusCompleted
        : AppConstants.paymentStatusPending,
    'paymentProvider': depositDispute ? AppConstants.paymentProviderXendit : '',
    'hasDeposit': depositDispute,
    'depositAmount': depositDispute ? 100.0 : 0.0,
    'depositStatus': depositDispute
        ? AppConstants.depositStatusHeld
        : AppConstants.depositStatusNotRequired,
    'createdAt': createdAt,
    'updatedAt': createdAt,
  });
}

ServiceRequestModel _serviceRequest({
  required String id,
  required String status,
  required DateTime createdAt,
}) {
  return ServiceRequestModel.fromMap(id, {
    'serviceTitle': 'Window cleaning',
    'providerName': 'Service Provider',
    'requesterName': 'Service Requester',
    'status': status,
    'amount': 50.0,
    'createdAt': createdAt,
    'updatedAt': createdAt,
  });
}

ReportModel _report({
  required String id,
  required String title,
  required String type,
  required String status,
  required DateTime createdAt,
}) {
  return ReportModel.fromMap(id, {
    'title': title,
    'type': type,
    'status': status,
    'reporterId': 'reporter-$id',
    'reporterName': 'Reporter $id',
    'reportedUserId': 'target-$id',
    'reportedUserName': 'Target $id',
    'description': 'Report details for $title.',
    'createdAt': createdAt,
    'updatedAt': createdAt,
  });
}
