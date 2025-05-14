import 'package:flutter_test/flutter_test.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'fake_auth_api.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  group('AuthRepository Tests', () {
    late AuthRepository authRepository;
    late FakeAuthApi fakeAuthApi;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      fakeAuthApi = FakeAuthApi(mockClient: mockClient);
      authRepository = AuthRepository(authApi: fakeAuthApi);
    });

    test('Test successful login', () async {
      final response = await authRepository.login(
          email: 'test@example.com', password: 'password');

      expect(response['message'], 'User logged in successfully');
    });

    test('Test successful signup', () async {
      final response = await authRepository.signup(
          email: 'test@example.com', password: 'password');

      expect(response['message'], 'User signed up successfully');
    });

    test('Test successful update user details', () async {
      final response = await authRepository.updateUserDetails(
          name: 'John Doe', number: '1234567890');

      expect(response['message'], 'User details updated successfully');
    });

    test('Test successful forgot password', () async {
      final response = await authRepository.forgotPassword(
          email: 'test@example.com', password: 'new_password');

      expect(response['message'], 'Password updated successfully');
    });

    test('Test successful send OTP', () async {
      final response = await authRepository.sendOtp(email: 'test@example.com');

      expect(response['message'], 'OTP sent successfully');
    });

    test('Test successful get user info', () async {
      final response = await authRepository.getUserInfo();

      expect(response.name, 'John Doe');
      expect(response.email, 'john@example.com');
    });

    test('Test successful verify OTP', () async {
      final response = await authRepository.verifyOtp(
          email: 'test@example.com', otp: 123456);

      expect(response['message'], 'OTP verified successfully');
    });

    test('Test successful update password', () async {
      final response = await authRepository.updatePassword(
          currentPassword: 'old_password',
          newPassword: 'new_password',
          email: 'test@example.com');

      expect(response['message'], 'Password updated successfully');
    });

    test('Test successful delete agent account', () async {
      final response = await authRepository.deleteAgentAccount(
          agentEmail: 'agent@example.com');

      expect(response['message'], 'Agent deleted successfully');
    });

    test('Test successful fetch users by agent ID', () async {
      final response =
          await authRepository.fetchUsersByAgentId('agent@example.com');

      expect(response.length, 2);
    });

    test('Test successful fetch users by role', () async {
      final response = await authRepository.fetchUsersByRole('User');

      expect(response.length, 2);
    });

    test('Test successful get parsed notifications', () async {
      final response = await authRepository.getParsedNotifications();

      expect(response.length, 2);
    });

    test('Test successful update notification read', () async {
      final response = await authRepository.updateNotificationRead('1');

      expect(response['message'], 'Notification marked as read');
    });

    test('Test successful update FCM token', () async {
      final response = await authRepository.updateFCMToken('fcm_token');

      expect(response['message'], 'FCM token updated successfully');
    });

    test('Test successful refresh token', () async {
      final response = await authRepository.refreshToken('old_token');

      expect(response['message'], 'Token refreshed successfully');
    });

    test('Test successful get agent', () async {
      final response = await authRepository.getAgent();

      expect(response.length, 2);
    });

    test('Test successful add agent', () async {
      final response = await authRepository.addAgent(
          body: {'email': 'agent@example.com', 'password': 'password'});

      expect(response['message'], 'Agent added successfully');
    });

    test('Test successful assign agent', () async {
      final response =
          await authRepository.assignAgent(email: 'agent@example.com');

      expect(response['message'], 'Agent assigned successfully');
    });

    test('Test successful remove assigned agent', () async {
      final response =
          await authRepository.removeAssignedAgent(email: 'agent@example.com');

      expect(response, true);
    });

    test('Test successful delete user account', () async {
      final response = await authRepository.deleteUserAccount(
          'test@example.com', 'password');

      expect(response['message'], 'User account deleted successfully');
    });
  });
}
