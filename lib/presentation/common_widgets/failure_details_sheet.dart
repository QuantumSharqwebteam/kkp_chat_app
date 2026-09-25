import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

/// Full-detail failure report with a copy button.
///
/// A snackbar is too small and vanishes before it can be read. The devices that
/// actually fail are rarely the ones attached to a debugger, so a tester needs
/// to see which stage broke and be able to paste the technical detail into a
/// bug report.
///
/// [stage] names the step that failed ("Picker", "Compression", "S3", …),
/// [message] is the sentence the user can act on, and [detail] is the
/// technical text. [location] is the throwing method and [stackTrace] the
/// call path — both are rendered so a report says *where in the code* it
/// broke, not just that it did.
void showFailureDetailsSheet(
  BuildContext context, {
  required String title,
  required String stage,
  required String message,
  String? detail,
  File? file,
  StackTrace? stackTrace,
  String? location,
}) {
  final codePath = _appFrames(stackTrace);

  final report = StringBuffer()
    ..writeln('$title ($stage)')
    ..writeln(message);
  if (location != null && location.isNotEmpty) {
    report.writeln('thrownAt: $location');
  }
  if (detail != null && detail.isNotEmpty) {
    report
      ..writeln()
      ..writeln(detail);
  }
  if (codePath.isNotEmpty) {
    report
      ..writeln()
      ..writeln('--- code path ---')
      ..writeln(codePath);
  }

  // Environment block — this is what makes a pasted report diagnosable without
  // the device in hand. The clock lines matter because S3 signs requests with
  // device time and rejects anything more than ~15 minutes out.
  final now = DateTime.now();
  report
    ..writeln()
    ..writeln('--- environment ---')
    ..writeln(
        'os: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
    ..writeln('deviceTime: ${now.toIso8601String()} '
        '(utc${now.timeZoneOffset.isNegative ? "-" : "+"}'
        '${now.timeZoneOffset.abs().inHours}, ${now.timeZoneName})')
    ..writeln('utc: ${now.toUtc().toIso8601String()}');
  if (file != null) {
    report.writeln('pickedFile: ${file.path}');
    try {
      report.writeln('pickedBytes: ${file.lengthSync()}');
    } catch (e) {
      // Distinguishes a permissions problem from a format problem.
      report.writeln('pickedBytes: unreadable ($e)');
    }
  }
  final reportText = report.toString().trim();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            // Keeps the actions above the keyboard / gesture bar.
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(title, style: AppTextStyles.black18_600)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stage,
                      style: AppTextStyles.black12_400
                          .copyWith(color: const Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(message, style: AppTextStyles.black14_400),
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.code_rounded,
                        size: 15, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (detail != null && detail.isNotEmpty ||
                  codePath.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Technical details',
                    style: AppTextStyles.black12_500
                        .copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: SelectableText(
                        [
                          if (detail != null && detail.isNotEmpty) detail,
                          if (codePath.isNotEmpty) 'code path:\n$codePath',
                        ].join('\n\n'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: reportText));
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text('Error details copied'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The app's own frames from [stackTrace], most recent first.
///
/// A raw Flutter stack is mostly framework internals; keeping only
/// `package:kkpchatapp` frames leaves the lines that actually point at our
/// code. Falls back to the first few raw frames when nothing matches (e.g. a
/// failure thrown from inside a plugin).
String _appFrames(StackTrace? stackTrace, {int limit = 8}) {
  if (stackTrace == null) return '';
  final lines = stackTrace
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final appLines =
      lines.where((line) => line.contains('package:kkpchatapp')).toList();
  final chosen = appLines.isNotEmpty ? appLines : lines;
  return chosen.take(limit).join('\n');
}
