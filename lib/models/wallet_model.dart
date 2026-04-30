// lib/models/wallet_model.dart

class WalletModel {
  final String walletId;
  final String userId;
  final double balance;
  final double totalSpent;
  final double totalReceived;
  final DateTime lastUpdated;
  final String currency;

  WalletModel({
    required this.walletId,
    required this.userId,
    required this.balance,
    this.totalSpent = 0.0,
    this.totalReceived = 0.0,
    required this.lastUpdated,
    this.currency = '₦',
  });

  Map<String, dynamic> toJson() => {
        'wallet_id': walletId,
        'user_id': userId,
        'balance': balance,
        'total_spent': totalSpent,
        'total_received': totalReceived,
        'last_updated': lastUpdated.toIso8601String(),
        'currency': currency,
      };

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        walletId: json['wallet_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
        totalReceived: (json['total_received'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: json['last_updated'] != null
            ? DateTime.parse(json['last_updated'] as String)
            : DateTime.now(),
        currency: json['currency'] as String? ?? '₦',
      );

  WalletModel copyWith({
    String? walletId,
    String? userId,
    double? balance,
    double? totalSpent,
    double? totalReceived,
    DateTime? lastUpdated,
    String? currency,
  }) =>
      WalletModel(
        walletId: walletId ?? this.walletId,
        userId: userId ?? this.userId,
        balance: balance ?? this.balance,
        totalSpent: totalSpent ?? this.totalSpent,
        totalReceived: totalReceived ?? this.totalReceived,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        currency: currency ?? this.currency,
      );
}
