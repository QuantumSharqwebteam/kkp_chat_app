import 'package:flutter_test/flutter_test.dart';
import 'auth/fake_verification_provider.dart';

void main() {
  late FakeVerificationProvider fakeVerificationProvider;

  setUp(() {
    fakeVerificationProvider = FakeVerificationProvider();
  });

  test('verifyOtp with empty OTP should set error text', () async {
    fakeVerificationProvider.setOtp('');
    final result =
        await fakeVerificationProvider.verifyOtp('valid@example.com');
    expect(result, false);
    expect(fakeVerificationProvider.errorText, 'Please enter the OTP');
    expect(fakeVerificationProvider.isOtpError, true);
  });

  test('verifyOtp with invalid OTP length should set error text', () async {
    fakeVerificationProvider.setOtp('12345');
    final result =
        await fakeVerificationProvider.verifyOtp('valid@example.com');
    expect(result, false);
    expect(fakeVerificationProvider.errorText, 'OTP must be 6 digits long');
    expect(fakeVerificationProvider.isOtpError, true);
  });

  test('verifyOtp with valid OTP should return true', () async {
    fakeVerificationProvider.setOtp('123456');
    final result =
        await fakeVerificationProvider.verifyOtp('valid@example.com');
    expect(result, true);
    expect(fakeVerificationProvider.errorText, isNull);
    expect(fakeVerificationProvider.isOtpError, false);
  });

  test('verifyOtp with invalid OTP should set error text', () async {
    fakeVerificationProvider.setOtp('654321');
    final result =
        await fakeVerificationProvider.verifyOtp('valid@example.com');
    expect(result, false);
    expect(fakeVerificationProvider.errorText, 'Invalid OTP');
    expect(fakeVerificationProvider.isOtpError, true);
  });
}
