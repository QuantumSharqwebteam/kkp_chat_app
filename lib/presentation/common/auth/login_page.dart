import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/logic/auth/login_provider.dart';
import 'package:kkpchatapp/presentation/common/auth/forgot_pass_page.dart';
import 'package:kkpchatapp/presentation/common/auth/signup_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final locale = AppLocalizations.of(context)!;

    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),
              SizedBox(
                height: Utils().height(context) * 0.4,
                width: double.infinity,
                child: SvgPicture.asset(
                  'assets/images/Login.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 3, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Welcome",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            locale.email,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 5),
                        CustomTextField(
                          errorText: loginProvider.emailError.trim().isEmpty
                              ? null
                              : loginProvider.emailError,
                          controller: _email,
                          maxLines: 1,
                          keyboardType: TextInputType.emailAddress,
                          hintText: locale.enterYourEmail,
                          onChanged: (value) => loginProvider.setEmail(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            locale.password,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 5),
                        CustomTextField(
                          errorText: loginProvider.passwordError.trim().isEmpty
                              ? null
                              : loginProvider.passwordError,
                          controller: _pass,
                          maxLines: 1,
                          isPassword: true,
                          keyboardType: TextInputType.visiblePassword,
                          hintText: locale.enterPassword,
                          onChanged: (value) => loginProvider.setPassword(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPassPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    loginProvider.isLoading
                        ? Center(child: const CupertinoActivityIndicator(radius: 20))
                        : CustomButton(
                            text: locale.login,
                            onPressed: () {
                              loginProvider.login(context, _email.text, _pass.text);
                            },
                          ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: locale.dontHaveAccount,
                          style: AppTextStyles.black10_500,
                          children: [
                            WidgetSpan(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SignupPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  locale.signup,
                                  style: AppTextStyles.black12_700,
                                ),
                              ),
                            ),
                          ],
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
    );

    return BackPressHandler(child: content);
  }
}
