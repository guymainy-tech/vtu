import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast_message.dart';

class CreatePinScreen extends StatefulWidget {
  final String phoneNumber;

  const CreatePinScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;

  Future<void> _savePin(String pin) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.createPin(pin);

    if (!mounted) return;

    if (success) {
      ToastMessage.show(
        context,
        message: 'PIN created successfully!',
        isSuccess: true,
      );
      context.go('/dashboard');
    } else {
      ToastMessage.show(
        context,
        message: 'Failed to create PIN. Try again.',
        isError: true,
      );

      setState(() {
        _reset();
      });
    }
  }

  void _onNumberTap(String number) {
    if (!_isConfirming) {
      if (_pin.length < 4) {
        setState(() => _pin += number);

        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              _isConfirming = true;
            });
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += number);

        if (_confirmPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _validatePin();
          });
        }
      }
    }
  }

  void _validatePin() {
    if (_pin == _confirmPin) {
      _savePin(_pin);
    } else {
      ToastMessage.show(
        context,
        message: 'PINs do not match',
        isError: true,
      );

      setState(() {
        _reset();
      });
    }
  }

  void _onBackspace() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _reset() {
    _pin = '';
    _confirmPin = '';
    _isConfirming = false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🔐 ICON
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: 30),

                // 📝 TITLE
                Text(
                  _isConfirming
                      ? 'Confirm your PIN'
                      : 'Create Transaction PIN',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _isConfirming
                      ? 'Re-enter your 4-digit PIN'
                      : 'Enter a 4-digit PIN',
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 40),

                // 🔢 PIN DISPLAY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final current =
                        _isConfirming ? _confirmPin : _pin;

                    final filled = index < current.length;

                    return Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: filled
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          filled ? '●' : '',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // 🔢 PIN PAD
                Expanded(child: _buildPinPad()),
              ],
            ),
          ),

          // ⏳ LOADING
          if (authProvider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPinPad() {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      '','0','⌫'
    ];

    return GridView.builder(
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];

        if (key.isEmpty) return const SizedBox();

        if (key == '⌫') {
          return IconButton(
            onPressed: _onBackspace,
            icon: const Icon(Icons.backspace_outlined),
          );
        }

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
          ),
          onPressed: () => _onNumberTap(key),
          child: Text(
            key,
            style: const TextStyle(fontSize: 22),
          ),
        );
      },
    );
  }
}