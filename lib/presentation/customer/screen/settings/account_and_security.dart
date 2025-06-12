// Ensure all necessary imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:kkpchatapp/presentation/common_widgets/settings_tile.dart';

class AccountAndSecurity extends StatefulWidget {
  const AccountAndSecurity({super.key});

  @override
  State<AccountAndSecurity> createState() => _AccountAndSecurityState();
}

class _AccountAndSecurityState extends State<AccountAndSecurity> {
  String? role = "";

  @override
  void initState() {
    getRole();
    super.initState();
  }

  void getRole() async {
    role = await LocalDbHelper.getUserType();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: Center(
        child: SizedBox(
          width: Utils().width(context) * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account & Security', style: AppTextStyles.black20_500),
              SizedBox(height: 16),
              Text('Login & recovery', style: AppTextStyles.black16_500),
              Text(
                'Manage your password, login preference and recovery methods',
                style: AppTextStyles.black14_400,
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SettingsTile(
                  titles: ['Change password'],
                  numberOfTiles: 1,
                  isDense: true,
                  onTaps: [
                    () {
                      Navigator.pushNamed(
                          context, CustomerRoutes.changePassword);
                    }
                  ],
                ),
              ),
              Spacer(),
              if (role == "0")
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SettingsTile(
                    titles: ['Delete Account Permanently'],
                    tileTitleStyle: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    numberOfTiles: 1,
                    isDense: true,
                    onTaps: [
                      () {
                        confirmDelete(context);
                      }
                    ],
                    trailingIconColor: Colors.red,
                    leadingIcons: [Icons.delete_forever_rounded],
                    iconColor: Colors.red,
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future confirmDelete(BuildContext context) {
  return showModalBottomSheet(
    useSafeArea: true,
    context: context,
    isDismissible: false,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: Utils().height(context) * 0.8,
      minHeight: Utils().height(context) * 0.6,
    ),
    elevation: 10,
    builder: (BuildContext ctx) {
      return ConfirmDeleteBottomSheet(
        scaffoldMessenger: ScaffoldMessenger.of(context),
      );
    },
  );
}

class ConfirmDeleteBottomSheet extends StatefulWidget {
  final ScaffoldMessengerState scaffoldMessenger;

  const ConfirmDeleteBottomSheet({super.key, required this.scaffoldMessenger});

  @override
  State<ConfirmDeleteBottomSheet> createState() =>
      _ConfirmDeleteBottomSheetState();
}

class _ConfirmDeleteBottomSheetState extends State<ConfirmDeleteBottomSheet> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController feedback = TextEditingController();

  String? emailError;
  String? passwordError;
  String? feedbackError;
  bool isLoading = false;

  final AuthApi authApi = AuthApi();

  Future<void> deleteAccount(BuildContext context) async {
    setState(() => isLoading = true);

    try {
      final response = await authApi.deleteUserAccount(
        email.text,
        password.text,
        feedback.text,
      );
      
      final message = response['message'];
      widget.scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));

      if (message == "User marked as deleted successfully") {
        await clearHiveStorage();
        logOut(context);
      }
    } catch (e) {
      widget.scaffoldMessenger
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> clearHiveStorage() async {
    final boxNames = await Hive.openBox('boxNames');
    for (var boxName in boxNames.keys) {
      await Hive.deleteBoxFromDisk(boxName);
    }
    await boxNames.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: Utils().width(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Text("Confirm Account Deletion", style: AppTextStyles.black18_600),
            SizedBox(height: 10),
            SizedBox(
              width: Utils().width(context) * 0.9,
              child: Text(
                "By entering email and password you confirm that this account can be permanently deleted, and cannot be recovered in any way.",
                style: AppTextStyles.black14_400,
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              controller: email,
              hintText: "Email",
              errorText: emailError,
              width: Utils().width(context) * 0.8,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            CustomTextField(
              controller: password,
              errorText: passwordError,
              hintText: "Password",
              width: Utils().width(context) * 0.8,
              keyboardType: TextInputType.visiblePassword,
              isPassword: true,
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: feedback,
              errorText: feedbackError,
              hintText: "Feedback",
              width: Utils().width(context) * 0.8,
              keyboardType: TextInputType.text,
              isPassword: false,
            ),
            SizedBox(height: 20),
            isLoading
                ? CupertinoActivityIndicator(radius: 20)
                : CustomButton(
                  text: "Confirm Delete",
                  onPressed: isLoading
               ? null
               : () {
               setState(() {
                emailError = email.text.trim().isEmpty
                ? "Email is required"
                : null;
                passwordError = password.text.trim().isEmpty
                ? "Password is required"
                : null;
               feedbackError = feedback.text.trim().isEmpty
                ? "Feedback is required"
                : null;
              });

              if (emailError == null &&
                passwordError == null &&
                feedbackError == null) {
              deleteAccount(context);
            }
          },
             width: Utils().width(context) * 0.8,
              backgroundColor: Colors.red.shade100,
             textColor: Colors.red,
             ),

          ],
        ),
      ),
    );
  }
}




void logOut(BuildContext context) async {
  try {
    // 1. Clear all persistent data
    await Future.wait([
      LocalDbHelper.removeToken(),
      LocalDbHelper.removeUserType(),
      LocalDbHelper.removeEmail(),
      LocalDbHelper.removeName(),
      LocalDbHelper.removeProfile(),
      LocalDbHelper.clearFCMToken(),
      NotificationService.deleteFCMToken(),
    ]);

    // 2. Dispose socket
    SocketService socketService = SocketService(navigatorKey);
    socketService.dispose();

    // 3. If still in UI, navigate:
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        "/login", // ← the named route you defined
        (Route<dynamic> route) => false, // ← clears everything
      );
    }
  } catch (e) {
    debugPrint("Error during logout: $e");
  }
}
