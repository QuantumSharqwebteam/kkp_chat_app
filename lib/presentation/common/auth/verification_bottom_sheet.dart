import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/auth/verification_provider.dart' show VerificationProvider;
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class VerificationBottomSheet extends StatefulWidget {
  final String email;
  final String token;

  const VerificationBottomSheet({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<VerificationBottomSheet> createState() => _VerificationBottomSheetState();
}

class _VerificationBottomSheetState extends State<VerificationBottomSheet> {
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final verificationProvider = Provider.of<VerificationProvider>(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.emailVerification,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '${l.verificationCodeSent} ${widget.email}',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Pinput(
              controller: _otp,
              length: 6,
              onChanged: (value) {
                verificationProvider.setOtp(value);
              },
            ),
            SizedBox(height: 20),
            CustomButton(
              text: "Verify",
              onPressed: () async {
                if (await verificationProvider.verifyOtp(
                  context,
                  widget.email,
                  token: widget.token,
                )) {
                  // After successful verification, save token, email, and role
                  await LocalDbHelper.saveToken(widget.token);
                  await LocalDbHelper.saveEmail(widget.email);
                  await LocalDbHelper.saveUserType("0"); // Assuming role is 0 for customer
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, CustomerRoutes.customerHost);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
