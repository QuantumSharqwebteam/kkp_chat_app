// Ensure all necessary imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
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
        toolbarHeight: kToolbarHeight,
        title: Text(AppLocalizations.of(context)!.accountAndSecurity,
            style: AppTextStyles.black20_500),
      ),
      body: Center(
        child: SizedBox(
          width: Utils().width(context) * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(AppLocalizations.of(context)!.accountAndSecurity,
              //     style: AppTextStyles.black20_500),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.loginAndRecovery,
                  style: AppTextStyles.black16_500),
              Text(
                "Manage your account",
                style: AppTextStyles.black14_400,
              ),
              Text("Login preference and recovery methods", style: AppTextStyles.black14_400),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SettingsTile(
                  titles: [AppLocalizations.of(context)!.changePassword],
                  numberOfTiles: 1,
                  isDense: true,
                  onTaps: [
                    () {
                      Navigator.pushNamed(context, CustomerRoutes.changePassword);
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
                    titles: [AppLocalizations.of(context)!.deleteAccountPermanently],
                    tileTitleStyle:
                        TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w700),
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
              SizedBox(height: 100),
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
  State<ConfirmDeleteBottomSheet> createState() => _ConfirmDeleteBottomSheetState();
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

  Future<void> _showFinalDeleteConfirmationDialog(
    BuildContext sheetContext,
  ) async {
    return showDialog<void>(
      context: sheetContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Final Confirmation"),
          content: const Text(
            "Are you absolutely sure you want to delete your account?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // close dialog
              },
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // close dialog
                deleteAccount(sheetContext); // ✅ pass SHEET context
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAccount(BuildContext sheetContext) async {
    setState(() => isLoading = true);

    try {
      final response = await authApi.deleteUserAccount(
        email.text,
        password.text,
        feedback.text,
      );

      final message = response['message'];

      if (message == "User marked as deleted successfully") {
        widget.scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Account deleted successfully")),
        );

        // ✅ Close bottom sheet
        if (sheetContext.mounted) {
          Navigator.of(sheetContext).pop();
        }

        await clearHiveStorage();

        // ✅ ALWAYS redirect via root navigator
        await logOut();
      } else {
        widget.scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Cannot delete account! Incorrect details provided"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
            Text(AppLocalizations.of(context)!.confirmAccountDeletion,
                style: AppTextStyles.black18_600),
            SizedBox(height: 10),
            SizedBox(
              width: Utils().width(context) * 0.9,
              child: Text(
                AppLocalizations.of(context)!.deleteAccountConfirmation,
                style: AppTextStyles.black14_400,
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              controller: email,
              hintText: AppLocalizations.of(context)!.emailLabel,
              errorText: emailError,
              width: Utils().width(context) * 0.8,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            CustomTextField(
              controller: password,
              errorText: passwordError,
              hintText: AppLocalizations.of(context)!.password,
              width: Utils().width(context) * 0.8,
              keyboardType: TextInputType.visiblePassword,
              isPassword: true,
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: feedback,
              errorText: feedbackError,
              hintText: AppLocalizations.of(context)!.reasonForDeleting,
              width: Utils().width(context) * 0.8,
              keyboardType: TextInputType.text,
              isPassword: false,
            ),
            SizedBox(height: 20),
            isLoading
                ? CupertinoActivityIndicator(radius: 20)
                : CustomButton(
                    text: AppLocalizations.of(context)!.confirmDelete,
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              emailError = email.text.trim().isEmpty ? "Email is required" : null;
                              passwordError =
                                  password.text.trim().isEmpty ? "Password is required" : null;
                              feedbackError =
                                  feedback.text.trim().isEmpty ? "Feedback is required" : null;
                            });

                            if (emailError == null &&
                                passwordError == null &&
                                feedbackError == null) {
                              _showFinalDeleteConfirmationDialog(context);
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

Future<void> logOut() async {
  try {
    await Future.wait([
      LocalDbHelper.removeToken(),
      LocalDbHelper.removeUserType(),
      LocalDbHelper.removeEmail(),
      LocalDbHelper.removeName(),
      LocalDbHelper.removeProfile(),
      LocalDbHelper.clearFCMToken(),
      NotificationService.deleteFCMToken(),
    ]);

    SocketService socketService = SocketService(navigatorKey);
    socketService.dispose();

    final rootContext = navigatorKey.currentContext;

    if (rootContext != null) {
      Navigator.of(rootContext).pushNamedAndRemoveUntil(
        "/login",
        (route) => false,
      );
    }
  } catch (e) {
    debugPrint("Error during logout: $e");
  }
}
