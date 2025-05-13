import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

class VerificationProvider with ChangeNotifier {
  String _otp = '';
  bool _isVerifyLoading = false;
  bool _isResendEnabled = true;
  int _timerCount = 60;
  Timer? _timer;
  bool _isOtpError = false;
  String? _errorText;

  String get otp => _otp;
  bool get isVerifyLoading => _isVerifyLoading;
  bool get isResendEnabled => _isResendEnabled;
  int get timerCount => _timerCount;
  bool get isOtpError => _isOtpError;
  String? get errorText => _errorText;

  void setOtp(String otp) {
    _otp = otp;
    notifyListeners();
  }

  void setIsVerifyLoading(bool isVerifyLoading) {
    _isVerifyLoading = isVerifyLoading;
    notifyListeners();
  }

  void setIsResendEnabled(bool isResendEnabled) {
    _isResendEnabled = isResendEnabled;
    notifyListeners();
  }

  void setTimerCount(int timerCount) {
    _timerCount = timerCount;
    notifyListeners();
  }

  void setIsOtpError(bool isOtpError) {
    _isOtpError = isOtpError;
    notifyListeners();
  }

  void setErrorText(String? errorText) {
    _errorText = errorText;
    notifyListeners();
  }

  Future<bool> verifyOtp(BuildContext context, String email) async {
    setIsVerifyLoading(true);
    setIsOtpError(false);

    if (_otp.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter the OTP')));
      setErrorText('Please enter the OTP');
      setIsVerifyLoading(false);
      setIsOtpError(true);
      return false;
    }

    if (_otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OTP must be 6 digits long')));
      setErrorText("OTP must be 6 digits long");
      setIsVerifyLoading(false);
      setIsOtpError(true);
      return false;
    }

    try {
      final response =
          await AuthRepository().verifyOtp(email: email, otp: int.parse(_otp));

      if (response['message'] == "OTP Verified Successfully!") {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response['message'])));
        }
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response['message'])));
        }
        setErrorText(response['message']);
        setIsOtpError(true);
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$e"),
          ),
        );
      }
      setErrorText(e.toString());
      setIsOtpError(true);
      return false;
    } finally {
      setIsVerifyLoading(false);
    }
  }

  void startTimer() {
    setTimerCount(90);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerCount > 0) {
        setTimerCount(_timerCount - 1);
      } else {
        setIsResendEnabled(true);
        _timer?.cancel();
      }
    });
  }

  void resendOtp(String email) async {
    await AuthRepository().sendOtp(email: email);
    setIsResendEnabled(false);
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
