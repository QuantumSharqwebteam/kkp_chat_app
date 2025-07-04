import 'package:flutter_test/flutter_test.dart';
import 'auth/fake_signup_provider.dart';

void main() {
  final FakeSignupProvider fakeSignupProvider = FakeSignupProvider();

  setUp(() {
    fakeSignupProvider;
  });

  test('signup with empty name should set name error', () async {
    fakeSignupProvider.setName('');
    fakeSignupProvider.setEmail('valid@example.com');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('validpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.nameError, "Name can't be Empty");
  });

  test('signup with empty email should set email error', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('validpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.emailError, "Email can't be Empty");
  });

  test('signup with invalid email should set email error', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('invalidemail');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('validpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.emailError, "Please enter a valid email address");
  });

  test('signup with empty password should set password error', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('valid@example.com');
    fakeSignupProvider.setPassword('');
    fakeSignupProvider.setRePassword('validpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.passwordError, "Password can't be Empty");
  });

  test('signup with empty rePassword should set rePassword error', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('valid@example.com');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('');
    await fakeSignupProvider.signup();
    expect(
        fakeSignupProvider.rePasswordError, "Re-enter Password can't be Empty");
  });

  test('signup with mismatched passwords should set password errors', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('valid@example.com');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('mismatchedpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.passwordError, "Password doesn't match");
    expect(fakeSignupProvider.rePasswordError, "Password doesn't match");
  });

  test('signup with valid credentials should not set errors', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('valid@example.com');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('validpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.nameError, isNull);
    expect(fakeSignupProvider.emailError, isNull);
    expect(fakeSignupProvider.passwordError, isNull);
    expect(fakeSignupProvider.rePasswordError, isNull);
  });

  test('signup with existing email should set email error', () async {
    fakeSignupProvider.setName('Valid Name');
    fakeSignupProvider.setEmail('exists@example.com');
    fakeSignupProvider.setPassword('validpassword');
    fakeSignupProvider.setRePassword('validpassword');
    await fakeSignupProvider.signup();
    expect(fakeSignupProvider.emailError, "Email already exists.");
  });
}
