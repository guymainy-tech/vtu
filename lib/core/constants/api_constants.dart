// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://api.vtuplus.com/v1';
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String verifyOTP = '/auth/verify-otp';
  static const String resendOTP = '/auth/resend-otp';
  static const String login = '/auth/login';
  static const String createPin = '/auth/create-pin';
  static const String logout = '/auth/logout';
  
  // Wallet endpoints
  static const String walletBalance = '/wallet/balance';
  static const String fundWallet = '/wallet/fund';
  static const String transactions = '/wallet/transactions';
  
  // VTU endpoints
  static const String buyData = '/vtu/data';
  static const String buyAirtime = '/vtu/airtime';
  static const String getPlans = '/vtu/plans';
  static const String checkStatus = '/vtu/status';
}