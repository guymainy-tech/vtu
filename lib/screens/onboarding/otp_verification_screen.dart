// lib/screens/onboarding/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/toast_message.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _pinController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendTimer > 0 && mounted) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _apiService.resendOTP(widget.phoneNumber);
      setState(() {
        _resendTimer = 60;
      });
      ToastMessage.show(
        context,
        message: 'OTP resent successfully',
        isSuccess: true,
      );
    } catch (e) {
      ToastMessage.show(
        context,
        message: 'Failed to resend OTP',
        isError: true,
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      ToastMessage.show(
        context,
        message: 'Please enter the 6-digit OTP',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.verifyOTP(
        phone: widget.phoneNumber,
        otp: _otpCode,
      );

      if (response['success']) {
        // Navigate to PIN creation
        context.go(
          '/create-pin',
          extra: {
            'phone': widget.phoneNumber,
            'token': response['token'],
          },
        );

        ToastMessage.show(
          context,
          message: 'Phone number verified successfully!',
          isSuccess: true,
        );
      } else {
        ToastMessage.show(
          context,
          message: response['message'] ?? 'Invalid OTP',
          isError: true,
        );
      }
    } catch (e) {
      ToastMessage.show(
        context,
        message: 'Verification failed. Please try again.',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/register'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sms_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'We sent a 6-digit code to ',
                style: TextStyle(color: Colors.grey.shade600),
                children: [
                  TextSpan(
                    text: widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // OTP Input
            PinCodeTextField(
              length: 6,
              obscureText: false,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 60,
                fieldWidth: 50,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveColor: Colors.grey.shade300,
                activeColor: AppTheme.primaryColor,
                selectedColor: AppTheme.primaryColor,
              ),
              animationDuration: const Duration(milliseconds: 300),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              controller: _pinController,
              onCompleted: (value) {
                setState(() {
                  _otpCode = value;
                });
                _verifyOTP();
              },
              onChanged: (value) {
                setState(() {
                  _otpCode = value;
                });
              },
              appContext: context,
            ),
            const SizedBox(height: 24),

            // Verify Button
            CustomButton(
              text: 'Verify',
              onPressed: _verifyOTP,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 24),

            // Resend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (_resendTimer > 0)
                  Text(
                    'Resend in ${_resendTimer}s',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _resendOTP,
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            if (_isResending) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
