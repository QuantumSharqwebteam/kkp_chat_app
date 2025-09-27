import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/api/analytics_management_service.dart';
import 'package:kkpchatapp/data/models/activity_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AnalyticsManagementScreen extends StatefulWidget {
  const AnalyticsManagementScreen({super.key});

  @override
  State<AnalyticsManagementScreen> createState() =>
      _AnalyticsManagementScreenState();
}

class _AnalyticsManagementScreenState extends State<AnalyticsManagementScreen> {
  final String? baseUrl = dotenv.env["BASE_URL"];
  late Future<List<Activity>> futureActivities;
  bool isDownloading = false;
  bool isDeleting = false;
  // Future<List<Activity>> fetchActivities() async {
  //   final response = await http.get(Uri.parse("$baseUrl/activity/list"));

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final List<dynamic> message = data["message"];
  //     return message.map((e) => Activity.fromJson(e)).toList();
  //   } else {
  //     throw Exception("Failed to load activities");
  //   }
  // }
  // String _getFormattedDate(String rawDate) {
  //   final parsed = DateTime.tryParse(rawDate);
  //   if (parsed == null) return '';
  //   return DateFormat('MMMM d, yyyy').format(parsed); // e.g., "May 21, 2025"
  // }

  @override
  void initState() {
    super.initState();
    futureActivities = AnalyticsService().fetchActivities();
  }

  String _getFormattedDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date); // e.g., "May 21, 2025"
  }

  String _getFormattedTime(DateTime date) {
    return DateFormat('h:mm a').format(date); // e.g., "3:45 PM"
  }

  Future<void> downloadAsExcel(List<Activity> activities) async {
    setState(() {
      isDownloading = true;
    });

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue('Username'),
        TextCellValue('Activity'),
        TextCellValue('Timestamp'),
      ]);

      for (var activity in activities) {
        sheet.appendRow([
          TextCellValue(activity.username),
          TextCellValue(activity.featureUsed),
          TextCellValue(
              "${_getFormattedDate(activity.timestamp)} ${_getFormattedTime(activity.timestamp)}"),
        ]);
      }

      final bytes = excel.save();
      final formattedDate =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/analytics_$formattedDate.xlsx');
      await file.writeAsBytes(bytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File generated: ${file.path}')),
        );
      }

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint("⚠️ Could not open Excel file: ${result.message}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to open the file')),
          );
        }
      }
    } catch (e) {
      debugPrint('Excel generation error: $e');
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.analyticsManagement),
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // title: Text("Confirm Deletion"),
                      content: Text(locale.confirmDownloadExcel),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text(locale.cancel),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close the dialog
                            if (!isDownloading) {
                              setState(() {
                                isDownloading = true;
                              });
                              final activities = await futureActivities;
                              await downloadAsExcel(activities);
                              setState(() {
                                isDownloading = false;
                              });
                            }
                          },
                          child: Text(locale.confirm),
                        ),
                      ],
                    );
                  },
                );
              },
              child: isDownloading
                  ? const SizedBox(
                      width: 35,
                      height: 35,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(width: 1, color: AppColors.greyB2BACD),
                      ),
                      child: const Icon(Icons.download),
                    ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Activity>>(
        future: futureActivities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(locale.noActivitiesFound));
          }

          final activities = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              child: Column(
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // ListTile(
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(
                                              0xFFDCFCE7), // Light green background
                                          child: Icon(Icons.person,
                                              color: Colors
                                                  .green), // Optional: icon color
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                activity.username,
                                                style:
                                                    AppTextStyles.black14_600,
                                              ),
                                              Text(
                                                'Activity: ${activity.featureUsed}',
                                                style: AppTextStyles.black12_400
                                                    .copyWith(
                                                        fontSize: 14,
                                                        color: Colors.black45),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Text(activity.username),
                                        // Text("Activity: ${activity.featureUsed}"),
                                        // Column(
                                        //   crossAxisAlignment: CrossAxisAlignment.end,
                                        //   children: [
                                        //     Text(
                                        //       _getFormattedDate(activity.timestamp.toLocal()),
                                        //       style: AppTextStyles.black12_400
                                        //           .copyWith(color: Colors.black45),
                                        //     ),
                                        //     SizedBox(
                                        //       height: 8,
                                        //     ),
                                        //     // Text(
                                        //     //   _getFormattedTime(inquiry.date),
                                        //     //   style: AppTextStyles.black12_400,
                                        //     // ),
                                        //   ],
                                        // ),
// • ${_getFormattedTime(activity.timestamp)}
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _getFormattedDate(
                                                  activity.timestamp),
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              _getFormattedTime(
                                                  activity.timestamp),
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        )
                                        // ),
                                      ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            // title: Text("Confirm Deletion"),
                            content: Text(locale.confirmDeleteAllActivities),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: Text(locale.cancel),
                              ),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    setState(() => isDeleting = true);
                                    bool success = await AnalyticsService()
                                        .deleteAllData();
                                    setState(() => isDeleting = false);
                                    if (success) {
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(locale
                                                .allDataDeletedSuccessfully)),
                                      );
                                      // Refresh UI
                                      setState(() {});
                                    } else {
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                locale.failedToDeleteAllData)),
                                      );
                                    }
                                  },
                                  child: Text(locale.confirm)),
                            ],
                          );
                        },
                      );
                    },
                    // constraints: BoxConstraints(
                    //   minWidth: 150, // custom width
                    //   minHeight: 50, // custom height
                    // ),
                    // padding: EdgeInsets.zero,
                    color: Colors.white,
                    icon: Icon(
                      Icons.delete_forever,
                      size: 30,
                    ),
                  ),
                ),
              ),
              // ElevatedButton(
              //   onPressed: () {},
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.red,
              //     foregroundColor: Colors.white,
              //     padding: EdgeInsets.symmetric(horizontal: 34, vertical: 12),
              //     textStyle:
              //         TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     elevation: 5,
              //   ),
              //   child: Icon(Icons.delete_forever),
              // ),
            ],
          );
        },
      ),
    );
  }
}
