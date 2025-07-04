import 'package:flutter_test/flutter_test.dart';
import 'auth/fake_login_provider.dart';

void main() {
  final FakeLoginProvider fakeLoginProvider = FakeLoginProvider();

  setUp(() {
    fakeLoginProvider;
  });

  test('login with empty email should set email error', () async {
    await fakeLoginProvider.login('', 'password');
    expect(fakeLoginProvider.emailError, 'Email can\'t be empty');
  });

  test('login with invalid email should set email error', () async {
    await fakeLoginProvider.login('invalidemail', 'password');
    expect(fakeLoginProvider.emailError, 'Please enter a valid email address');
  });

  test('login with empty password should set password error', () async {
    await fakeLoginProvider.login('valid@example.com', '');
    expect(fakeLoginProvider.passwordError, 'Password can\'t be empty');
  });

  test('login with valid credentials should not set errors', () async {
    await fakeLoginProvider.login('valid@example.com', 'validpassword');
    expect(fakeLoginProvider.emailError, '');
    expect(fakeLoginProvider.passwordError, '');
  });

  test('login with invalid email should set email error', () async {
    await fakeLoginProvider.login('invalid@example.com', 'validpassword');
    expect(fakeLoginProvider.emailError, 'Invalid Email');
  });

  test('login with wrong password should set password error', () async {
    await fakeLoginProvider.login('valid@example.com', 'wrongpassword');
    expect(fakeLoginProvider.passwordError, 'Wrong password');
  });
}
