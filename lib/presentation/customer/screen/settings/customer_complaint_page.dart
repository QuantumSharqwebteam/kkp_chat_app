import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';

import '../../../../l10n/generated/app_localizations.dart';

class CustomerComplaintPage extends StatefulWidget {
  const CustomerComplaintPage({super.key});

  @override
  State<CustomerComplaintPage> createState() => _CustomerComplaintPageState();
}

class _CustomerComplaintPageState extends State<CustomerComplaintPage> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;
  String subjectError = "";
  String descriptionError = "";
  Future<void> submitComplaint() async {
    if (subjectController.text.isEmpty || descriptionController.text.isEmpty) {
      setState(() {
        if (subjectController.text.isEmpty) {
          subjectError = AppLocalizations.of(context)!.subjectCannotBeEmpty;
        }
        if (descriptionController.text.isEmpty) {
          descriptionError =
              AppLocalizations.of(context)!.descriptionCannotBeEmpty;
        }
      });
      return;
    }

    setState(() => isLoading = true);

    const String apiUrl = "http://54.234.201.60:5000/complaint/add";
    final token = await LocalDbHelper.getToken();
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "subject": subjectController.text,
          "description": descriptionController.text,
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .complaintSubmittedSuccessfully)),
        );
        subjectController.clear();
        descriptionController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
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
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  TextFormField(
                    controller: subjectController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
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
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  TextFormField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: descriptionController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 20),
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
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitComplaint,
                    child: Text(AppLocalizations.of(context)!.submitComplaint),
                  ),
          ],
        ),
      ),
    );
  }
}
