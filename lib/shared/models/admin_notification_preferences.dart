// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_notification_preferences.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,10-July-2026
// Last Edited on  : Saturday,18-July-2026

/// Admin settings: persisted notification toggles on admins/{uid}.notificationPreferences.
class AdminNotificationPreferences {
  const AdminNotificationPreferences({
    this.verificationAlerts = true,
    this.reportEscalations = true,
    this.serviceDisputeAlerts = true,
    this.weeklyDigest = false,
  });

  final bool verificationAlerts;
  final bool reportEscalations;
  final bool serviceDisputeAlerts;
  final bool weeklyDigest;

  static const AdminNotificationPreferences defaults =
      AdminNotificationPreferences();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'verificationAlerts': verificationAlerts,
      'reportEscalations': reportEscalations,
      'serviceDisputeAlerts': serviceDisputeAlerts,
      'weeklyDigest': weeklyDigest,
    };
  }

  factory AdminNotificationPreferences.fromMap(dynamic value) {
    if (value is! Map) {
      return defaults;
    }
    final map = Map<String, dynamic>.from(value);
    return AdminNotificationPreferences(
      verificationAlerts: map['verificationAlerts'] as bool? ?? true,
      reportEscalations: map['reportEscalations'] as bool? ?? true,
      serviceDisputeAlerts: map['serviceDisputeAlerts'] as bool? ?? true,
      weeklyDigest: map['weeklyDigest'] as bool? ?? false,
    );
  }

  AdminNotificationPreferences copyWith({
    bool? verificationAlerts,
    bool? reportEscalations,
    bool? serviceDisputeAlerts,
    bool? weeklyDigest,
  }) {
    return AdminNotificationPreferences(
      verificationAlerts: verificationAlerts ?? this.verificationAlerts,
      reportEscalations: reportEscalations ?? this.reportEscalations,
      serviceDisputeAlerts: serviceDisputeAlerts ?? this.serviceDisputeAlerts,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
    );
  }
}
