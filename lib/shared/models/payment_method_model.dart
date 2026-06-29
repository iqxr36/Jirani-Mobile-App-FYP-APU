class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.stripePaymentMethodId,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  final String id;
  final String stripePaymentMethodId;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final stripeId = (json['stripePaymentMethodId'] as String?) ??
        (json['id'] as String?) ??
        '';
    return PaymentMethodModel(
      id: (json['id'] as String?) ?? stripeId,
      stripePaymentMethodId: stripeId,
      brand: (json['brand'] as String?) ?? '',
      last4: (json['last4'] as String?) ?? '',
      expMonth: _toInt(json['expMonth']),
      expYear: _toInt(json['expYear']),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stripePaymentMethodId': stripePaymentMethodId,
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'isDefault': isDefault,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
