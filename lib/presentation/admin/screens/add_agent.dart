import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:kkpchatapp/logic/agent/agent_provider.dart';
import 'package:provider/provider.dart';

class AddAgent extends StatefulWidget {
  const AddAgent({super.key});

  @override
  State<AddAgent> createState() => _AddAgentState();
}

class _AddAgentState extends State<AddAgent> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  static const String agentRole = "Agent";
  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;

  bool validateName(String name) {
    if (name.length < 3) {
      setState(() {
        nameError = AppLocalizations.of(context)!.nameMinLengthError;
      });
      return false;
    } else {
      setState(() {
        nameError = null;
      });
      return true;
    }
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        emailError = AppLocalizations.of(context)!.validEmailError;
      });
      return false;
    } else {
      setState(() {
        emailError = null;
      });
      return true;
    }
  }

  bool validatePhone(String phone) {
    if (phone.length != 10 || int.tryParse(phone) == null) {
      setState(() {
        phoneError = AppLocalizations.of(context)!.phoneNumberLengthError;
      });
      return false;
    } else {
      setState(() {
        phoneError = null;
      });
      return true;
    }
  }

  bool validatePassword(String password) {
    if (password.length < 6) {
      setState(() {
        passwordError = AppLocalizations.of(context)!.passwordMinLengthError;
      });
      return false;
    } else {
      setState(() {
        passwordError = null;
      });
      return true;
    }
  }

  Future<void> signUpNewAgent() async {
    bool isValid = true;

    isValid &= validateName(fullNameController.text);
    isValid &= validateEmail(emailController.text);
    isValid &= validatePhone(phoneController.text);
    isValid &= validatePassword(passwordController.text);

    if (!isValid) {
      return;
    }

    final body = {
      "name": fullNameController.text,
      "email": emailController.text,
      "mobile": int.parse(phoneController.text),
      "role": agentRole,
      "password": passwordController.text
    };

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final response = await agentProvider.addAgent(body: body);

      if (response['message'] == "User signed up successfully") {
        if (mounted) {
          Utils()
              .showSuccessDialog(context, AppLocalizations.of(context)!.agentProfileCreated, true);
        }

        await agentProvider.assignAgentToList(email: emailController.text);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
        fullNameController.clear();
        emailController.clear();
        phoneController.clear();
        passwordController.clear();
      } else if (response["status"] == 400 || response["status"] == 401) {
        if (mounted) {
          Utils().showSuccessDialog(context, "${response["message"]}", false);
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          Utils().showSuccessDialog(context, AppLocalizations.of(context)!.failedToAddAgent, false);
        }
      }
    } catch (e) {
      debugPrint("Failed to add new agent: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(l.addAgent),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: agentProvider.isLoading
          ? FullScreenLoader()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 40),
                child: Card(
                  color: Colors.white,
                  elevation: 10,
                  surfaceTintColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(l.fullName),
                        CustomTextField(
                          controller: fullNameController,
                          hintText: l.enterFullName,
                          prefixIcon: const Icon(Icons.person),
                          errorText: nameError,
                        ),
                        Text(l.email),
                        CustomTextField(
                          controller: emailController,
                          hintText: l.enterEmail,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          errorText: emailError,
                        ),
                        Text(l.phoneNumber),
                        CustomTextField(
                          controller: phoneController,
                          hintText: l.enterPhoneNumber,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone),
                          maxLength: 10,
                          errorText: phoneError,
                        ),
                        Text(l.password),
                        CustomTextField(
                          controller: passwordController,
                          hintText: l.createPassword,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock),
                          errorText: passwordError,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          onPressed: signUpNewAgent,
                          fontSize: 18,
                          backgroundColor: AppColors.blue00ABE9,
                          text: l.addAgent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
