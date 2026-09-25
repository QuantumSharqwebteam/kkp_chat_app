import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/auth/signup_provider.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();
  bool _showPasswordRules = false;

  @override
  Widget build(BuildContext context) {
    final signupProvider = Provider.of<SignupProvider>(context);
    final l = AppLocalizations.of(context)!;

    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Image.asset(
                'assets/icons/logo.png',
                height: 25,
              ),
            )
          ],
        ),
        body: Center(
          heightFactor: 1.2,
          child: SizedBox(
            width: Utils().width(context) * 0.8,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    l.createAccount,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          l.fullName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _name,
                        errorText: signupProvider.nameError,
                        maxLines: 1,
                        keyboardType: TextInputType.name,
                        hintText: l.enterFullName,
                        onChanged: (value) => signupProvider.setName(value),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Email textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          l.email,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        errorText: signupProvider.emailError,
                        controller: _email,
                        maxLines: 1,
                        keyboardType: TextInputType.emailAddress,
                        hintText: l.enterEmail,
                        onChanged: (value) => signupProvider.setEmail(value),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Password textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          l.password,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _pass,
                        errorText: signupProvider.passwordError,
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        hintText: l.createPassword,
                        onChanged: (value) => signupProvider.setPassword(value),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _showPasswordRules = !_showPasswordRules;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blueGrey.shade600),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Password requirements',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                _showPasswordRules
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: Colors.blueGrey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'Must contain:\n'
                            '- At least 8 characters\n'
                            '- One uppercase letter\n'
                            '- One lowercase letter\n'
                            '- One number\n'
                            '- One special character',
                            style: TextStyle(fontSize: 12, height: 1.3, color: Colors.black87),
                          ),
                        ),
                        crossFadeState: _showPasswordRules
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Password textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          l.confirmPassword,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _repass,
                        errorText: signupProvider.rePasswordError,
                        borderRadius: 10,
                        height: 45,
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        hintText: l.confirmPassword,
                        onChanged: (value) => signupProvider.setRePassword(value),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  signupProvider.isLoading
                      ? CupertinoActivityIndicator(radius: 20)
                      : CustomButton(
                          text: l.createAccount,
                          onPressed: () {
                            signupProvider.signup(context);
                          },
                        ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: l.alreadyHaveAccount,
                      style: AppTextStyles.black10_500,
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) {
                                return LoginPage();
                              }));
                            },
                            child: Text(
                              l.login,
                              style: AppTextStyles.black12_700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return BackPressHandler(child: content);
  }
}
