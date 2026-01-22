import 'package:flutter/material.dart';
import 'package:kkpchatapp/logic/agent/complaints_provider.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/generated/app_localizations.dart';

class CustomerComplaintPage extends StatefulWidget {
  const CustomerComplaintPage({super.key});

  @override
  State<CustomerComplaintPage> createState() => _CustomerComplaintPageState();
}

class _CustomerComplaintPageState extends State<CustomerComplaintPage> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String subjectError = "";
  String descriptionError = "";
  Future<void> submitComplaint() async {
    if (subjectController.text.isEmpty || descriptionController.text.isEmpty) {
      setState(() {
        if (subjectController.text.isEmpty) {
          subjectError = AppLocalizations.of(context)!.subjectCannotBeEmpty;
        }
        if (descriptionController.text.isEmpty) {
          descriptionError = AppLocalizations.of(context)!.descriptionCannotBeEmpty;
        }
      });
      return;
    }

    final result = await context
        .read<ComplaintsProvider>()
        .submitComplaint(subject: subjectController.text, description: descriptionController.text);

    if (result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.complaintSubmittedSuccessfully)),
        );
      }
      subjectController.clear();
      descriptionController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit complaint!!! Try again later!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.complaints)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.subject,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  TextFormField(
                    controller: subjectController,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (val) {
                      if (subjectError.isNotEmpty && val.isNotEmpty) {
                        setState(() {
                          subjectError = "";
                        });
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF1976D2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (subjectError.isNotEmpty)
                    Text(subjectError, style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.description,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  TextFormField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: descriptionController,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (val) {
                      if (descriptionError.isNotEmpty && val.isNotEmpty) {
                        setState(() {
                          descriptionError = "";
                        });
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF1976D2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (descriptionError.isNotEmpty)
                    Text(descriptionError, style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            context.watch<ComplaintsProvider>().complaintSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitComplaint,
                    child: Text(AppLocalizations.of(context)!.submitComplaint),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
