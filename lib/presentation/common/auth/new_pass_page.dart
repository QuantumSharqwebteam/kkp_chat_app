import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/auth/new_pass_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:provider/provider.dart';

class NewPassPage extends StatefulWidget {
  const NewPassPage({super.key, required this.email});
  final String email;

  @override
  State<NewPassPage> createState() => _NewPassPageState();
}

class _NewPassPageState extends State<NewPassPage> {
  final _newpass = TextEditingController();
  final _repass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final newPassProvider = Provider.of<NewPassProvider>(context);
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
                      'assets/images/new_pass.png',
                      height: 300,
                    ),
                    Text(
                      l.createNewPassword,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      l.newPasswordRule,
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
                            l.newPassword,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(height: 5),
                        CustomTextField(
                          controller: _newpass,
                          maxLines: 1,
                          isPassword: true,
                          keyboardType: TextInputType.emailAddress,
                          hintText: l.enterPassword,
                          errorText: newPassProvider.newPassError,
                          onChanged: (value) => newPassProvider.setNewPassword(value),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            l.confirmNewPassword,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(height: 5),
                        CustomTextField(
                          controller: _repass,
                          maxLines: 1,
                          isPassword: true,
                          keyboardType: TextInputType.emailAddress,
                          hintText: l.reEnterPassword,
                          errorText: newPassProvider.rePassError,
                          onChanged: (value) => newPassProvider.setRePassword(value),
                        ),
                        SizedBox(height: 40),
                        newPassProvider.isLoading
                            ? const CircularProgressIndicator()
                            : CustomButton(
                                text: l.resetPassword,
                                onPressed: () {
                                  newPassProvider.changePassword(context, widget.email);
                                },
                              ),
                        SizedBox(height: 20),
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
