// Ensure all necessary imports
import 'package:flutter/cupertino.dart';
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
    if (mounted) setState(() {});
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
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.loginAndRecovery,
                  style: AppTextStyles.black16_500),
              Text(
                "Manage your account",
                style: AppTextStyles.black14_400,
              ),
              Text("Login preference and recovery methods",
                  style: AppTextStyles.black14_400),
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
                    titles: [
                      AppLocalizations.of(context)!.deleteAccountPermanently
                    ],
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
  State<ConfirmDeleteBottomSheet> createState() =>
      _ConfirmDeleteBottomSheetState();
}

class _ConfirmDeleteBottomSheetState extends State<ConfirmDeleteBottomSheet> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController feedback = TextEditingController();

  static final RegExp _emailRegex =
      RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]{2,}$');

  String? emailError;
  String? passwordError;
  String? feedbackError;
  String?
      generalError; // shown inside the sheet (snackbars on parent are hidden behind it)
  bool isLoading = false;

  String? _loggedInEmail;

  final AuthApi authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    _loadLoggedInEmail();

    // Clear a field's error as soon as the user edits it
    email.addListener(() {
      if (emailError != null || generalError != null) {
        setState(() {
          emailError = null;
          generalError = null;
        });
      }
    });
    password.addListener(() {
      if (passwordError != null || generalError != null) {
        setState(() {
          passwordError = null;
          generalError = null;
        });
      }
    });
    feedback.addListener(() {
      if (feedbackError != null) setState(() => feedbackError = null);
    });
  }

  Future<void> _loadLoggedInEmail() async {
    try {
      _loggedInEmail = LocalDbHelper.getEmail();
    } catch (e) {
      debugPrint("Could not read stored email: $e");
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    feedback.dispose();
    super.dispose();
  }

  /// Client-side validation. Returns true if everything is valid.
  bool _validateInputs() {
    final enteredEmail = email.text.trim();
    final enteredPassword = password.text; // don't trim passwords
    final enteredFeedback = feedback.text.trim();

    String? eErr;
    if (enteredEmail.isEmpty) {
      eErr = "Email is required";
    } else if (!_emailRegex.hasMatch(enteredEmail)) {
      eErr = "Enter a valid email address";
    } else if (_loggedInEmail != null &&
        _loggedInEmail!.isNotEmpty &&
        enteredEmail.toLowerCase() != _loggedInEmail!.trim().toLowerCase()) {
      eErr = "This email doesn't match your account";
    }

    String? pErr;
    if (enteredPassword.trim().isEmpty) {
      pErr = "Password is required";
    }

    String? fErr;
    if (enteredFeedback.isEmpty) {
      fErr = "Feedback is required";
    }

    setState(() {
      emailError = eErr;
      passwordError = pErr;
      feedbackError = fErr;
      generalError = null;
    });

    return eErr == null && pErr == null && fErr == null;
  }

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
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                deleteAccount(sheetContext);
              },
            ),
          ],
        );
      },
    );
  }

  /// Maps a failed server response to field-level errors.
  void _applyServerError(String? message) {
    final msg = (message ?? "").toLowerCase();

    setState(() {
      if (msg.contains("email") ||
          msg.contains("user not found") ||
          msg.contains("no user")) {
        emailError = "No account found with this email";
      } else if (msg.contains("password") ||
          msg.contains("credential") ||
          msg.contains("incorrect") ||
          msg.contains("invalid")) {
        passwordError = "Incorrect password";
      } else if (_loggedInEmail != null &&
          email.text.trim().toLowerCase() ==
              _loggedInEmail!.trim().toLowerCase()) {
        // Email already verified locally, so the password must be the problem
        passwordError = "Incorrect password";
      } else {
        emailError = "Incorrect email or password";
        passwordError = "Incorrect email or password";
      }
    });
  }

  Future<void> deleteAccount(BuildContext sheetContext) async {
    setState(() {
      isLoading = true;
      generalError = null;
    });

    try {
      final response = await authApi.deleteUserAccount(
        email.text.trim(),
        password.text,
        feedback.text.trim(),
      );

      final message = response['message']?.toString();

      if (message == "User marked as deleted successfully") {
        if (sheetContext.mounted) {
          Navigator.of(sheetContext).pop();
        }

        widget.scaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("Account deleted successfully")),
          );

        await Future.delayed(const Duration(seconds: 1));

        await clearHiveStorage();
        await logOut();
      } else {
        _applyServerError(message);
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
      // Many APIs throw on 401/400 — still try to show a useful field error
      final errText = e.toString().toLowerCase();
      if (errText.contains("401") ||
          errText.contains("403") ||
          errText.contains("password") ||
          errText.contains("credential")) {
        _applyServerError(errText);
      } else if (mounted) {
        setState(
            () => generalError = "Something went wrong. Please try again.");
      }
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
            if (generalError != null) ...[
              SizedBox(height: 12),
              SizedBox(
                width: Utils().width(context) * 0.8,
                child: Text(
                  generalError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
            SizedBox(height: 20),
            isLoading
                ? CupertinoActivityIndicator(radius: 20)
                : CustomButton(
                    text: AppLocalizations.of(context)!.confirmDelete,
                    onPressed: isLoading
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            if (_validateInputs()) {
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

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      "/login",
      (route) => false,
    );
  } catch (e) {
    debugPrint("Error during logout: $e");
  }
}
