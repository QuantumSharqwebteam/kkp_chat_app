import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
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

  final List<String> roles = ['Agent'];
  String selectedRole = 'Agent';

  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;

  bool validateName(String name) {
    if (name.length < 3) {
      setState(() {
        nameError = "Name should be at least 3 characters";
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
        emailError = "Please enter a valid email address";
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
        phoneError = "Phone number should be 10 digits";
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
        passwordError = "Password should be at least 6 characters";
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
      "role": selectedRole,
      "password": passwordController.text
    };

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final response = await agentProvider.addAgent(body: body);

      if (response['message'] == "User signed up successfully") {
        if (mounted) {
          Utils().showSuccessDialog(context, "Agent Profile created", true);
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
          Utils().showSuccessDialog(
              context, "Failed to add Agent, Try again later!", false);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Add Agent'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: agentProvider.isLoading
          ? FullScreenLoader()
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 40),
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
                        Text("Full Name"),
                        CustomTextField(
                          controller: fullNameController,
                          hintText: 'Enter full name',
                          prefixIcon: const Icon(Icons.person),
                          errorText: nameError,
                        ),
                        Text("Email Address"),
                        CustomTextField(
                          controller: emailController,
                          hintText: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          errorText: emailError,
                        ),
                        Text("Phone number"),
                        CustomTextField(
                          controller: phoneController,
                          hintText: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone),
                          maxLength: 10,
                          errorText: phoneError,
                        ),
                        Text("Password"),
                        CustomTextField(
                          controller: passwordController,
                          hintText: 'Create Password',
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock),
                          errorText: passwordError,
                        ),
                        Text("Role"),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          items: roles
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ))
                              .toList(),
                          onChanged: (value) {},
                          // (value) {
                          //   setState(() {
                          //     selectedRole = value!;
                          //   });
                          // },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          onPressed: signUpNewAgent,
                          fontSize: 18,
                          backgroundColor: AppColors.blue00ABE9,
                          text: "Add Agent",
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
