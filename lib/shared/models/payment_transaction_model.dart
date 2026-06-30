import 'package:cloud_firestore/cloud_firestore.dart';

/// Payments DB model: mirrors payments/{paymentId} records created by backend Stripe functions.
class PaymentTransactionModel {
  const PaymentTransactionModel({
    required this.id,
    required this.payerId,
    required this.receiverId,
    required this.paymentType,
    required this.relatedId,
    required this.itemId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.stripePaymentIntentId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String payerId;
  final String receiverId;
  final String paymentType;
  final String relatedId;
  final String itemId;
  final int amount;
  final String currency;
  final String status;
  final String stripePaymentIntentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Payments feature: builds a transaction model from a Firestore payment document snapshot.
  factory PaymentTransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PaymentTransactionModel.fromMap(snapshot.id, snapshot.data() ?? {});
  }

  /// Payments feature: maps stored payment fields such as payer, receiver, related borrow request, amount, and status.
  factory PaymentTransactionModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return PaymentTransactionModel(
      id: id,
      payerId: (data['payerId'] as String?) ?? '',
      receiverId: (data['receiverId'] as String?) ?? '',
      paymentType: (data['paymentType'] as String?) ?? '',
      relatedId: (data['relatedId'] as String?) ?? '',
      itemId: (data['itemId'] as String?) ?? '',
      amount: _toInt(data['amount']),
      currency: (data['currency'] as String?) ?? 'myr',
      status: (data['status'] as String?) ?? 'pending',
      stripePaymentIntentId:
          (data['stripePaymentIntentId'] as String?) ?? '',
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  /// Payments feature: writes payment metadata back in the same Firestore shape used by backend records.
  Map<String, dynamic> toJson() {
    return {
      'payerId': payerId,
      'receiverId': receiverId,
      'paymentType': paymentType,
      'relatedId': relatedId,
      'itemId': itemId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  /// Payments feature: normalizes minor-unit amount values from Firestore or callable responses.
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Payments feature: converts Firestore timestamps and serialized dates into nullable DateTime values.
  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
