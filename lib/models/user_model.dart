// lib/models/user_model.dart

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final double balance;
  final String? profileImageUrl;
  final String? transactionPin;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? virtualAccountNumber;
  final String? virtualAccountName;
  final bool hasVirtualAccount;
  final String? bvn;
  final String? nin;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.balance,
    this.profileImageUrl,
    this.transactionPin,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    required this.createdAt,
    this.lastLogin,
    this.virtualAccountNumber,
    this.virtualAccountName,
    this.hasVirtualAccount = false,
    this.bvn,
    this.nin,
  });

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'balance': balance,
        'profile_image_url': profileImageUrl,
        'transaction_pin': transactionPin,
        'is_phone_verified': isPhoneVerified,
        'is_email_verified': isEmailVerified,
        'created_at': createdAt.toIso8601String(),
        'last_login': lastLogin?.toIso8601String(),
        'virtual_account_number': virtualAccountNumber,
        'virtual_account_name': virtualAccountName,
        'has_virtual_account': hasVirtualAccount,
        'bvn': bvn,
        'nin': nin,
      };

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['userId'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        profileImageUrl: json['profile_image_url'] as String?,
        transactionPin: json['transaction_pin'] as String?,
        isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        lastLogin: json['last_login'] != null
            ? DateTime.parse(json['last_login'] as String)
            : null,
        virtualAccountNumber: json['virtual_account_number'] as String?,
        virtualAccountName: json['virtual_account_name'] as String?,
        hasVirtualAccount: json['has_virtual_account'] as bool? ?? false,
        bvn: json['bvn'] as String?,
        nin: json['nin'] as String?,
      );

  // Copy with method for immutability
  UserModel copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    double? balance,
    String? profileImageUrl,
    String? transactionPin,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? virtualAccountNumber,
    String? virtualAccountName,
    bool? hasVirtualAccount,
    String? bvn,
    String? nin,
  }) =>
      UserModel(
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        balance: balance ?? this.balance,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        transactionPin: transactionPin ?? this.transactionPin,
        isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        createdAt: createdAt ?? this.createdAt,
        lastLogin: lastLogin ?? this.lastLogin,
        virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
        virtualAccountName: virtualAccountName ?? this.virtualAccountName,
        hasVirtualAccount: hasVirtualAccount ?? this.hasVirtualAccount,
        bvn: bvn ?? this.bvn,
        nin: nin ?? this.nin,
      );
}
