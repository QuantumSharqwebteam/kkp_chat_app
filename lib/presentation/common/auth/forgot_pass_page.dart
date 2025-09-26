import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/utils/helper_functions.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/auth/forgot_pass_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:provider/provider.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final _email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final forgotPassProvider = Provider.of<ForgotPassProvider>(context);
    final l = AppLocalizations.of(context)!;
    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: Utils().width(context) * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Image.asset(
                      'assets/images/forgot.png',
                      height: 300,
                    ),
                    Text(
                      l.forgotPassword,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      l.resetPasswordMessage,
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
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
                          controller: _email,
                          maxLines: 1,
                          errorText: forgotPassProvider.errorText,
                          keyboardType: TextInputType.emailAddress,
                          hintText: l.enterEmail,
                          onChanged: (value) => forgotPassProvider.setEmail(value),
                        ),
                        SizedBox(height: 40),
                        forgotPassProvider.isLoading
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : CustomButton(
                                text: 'Submit',
                                onPressed: () {
                                  if (_email.text.isEmpty) {
                                    forgotPassProvider.setErrorText(l.emailEmptyError);
                                  } else if (!HelperFunctions().isValidEmail(_email.text)) {
                                    forgotPassProvider.setErrorText(l.validEmailError);
                                  } else {
                                    forgotPassProvider.setErrorText(null);
                                    forgotPassProvider.forgetPassword(context);
                                  }
                                },
                              ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 5),
                              Text(
                                l.backToLogin,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return BackPressHandler(child: content);
  }
}
