import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:open_file/open_file.dart';

class DocumentMessageBubble extends StatelessWidget {
  final String documentUrl;
  final bool isMe;
  final String timestamp;
  final VoidCallback? onLongPress;
  final bool isDeleted;
  final bool? read;

  const DocumentMessageBubble({
    super.key,
    required this.documentUrl,
    required this.isMe,
    required this.timestamp,
    this.read,
    this.onLongPress,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = Uri.parse(documentUrl).pathSegments.last;
    final shortFileName = _getShortFileName(fileName);

    Future<void> downloadAndOpenFile() async {
      try {
        final response = await http.get(Uri.parse(documentUrl));
        final bytes = response.bodyBytes;

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await OpenFile.open(file.path);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open file')),
          );
        }
      }
    }

    return isDeleted
        ? DeletedMessageBubble(isMe: isMe, timestamp: timestamp)
        : Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: downloadAndOpenFile,
              onLongPress: onLongPress,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.senderMessageBubbleColor
                      : AppColors.recieverMessageBubble,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFileTypeIcon(),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shortFileName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isMe)
                            Icon(
                              (read ?? false) ? Icons.done_all : Icons.done,
                              color:
                                  (read ?? false) ? Colors.blue : Colors.grey,
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildFileTypeIcon() {
    final ext = documentUrl.split('.').last.toLowerCase();
    if (['pdf'].contains(ext)) {
      return Icon(Icons.picture_as_pdf, size: 30, color: AppColors.inActiveRed);
    }
    if (['doc', 'docx'].contains(ext)) {
      return Icon(Icons.article, size: 30, color: AppColors.bluePrimary);
    }
    if (['xls', 'xlsx'].contains(ext)) {
      return Icon(Icons.grid_on, size: 30, color: AppColors.activeGreen);
    }
    if (['txt'].contains(ext)) {
      return Icon(Icons.notes, size: 30, color: AppColors.grey525252);
    }
    return Icon(Icons.description, size: 30);
  }

  String _getShortFileName(String fileName) {
    final parts = fileName.split('.');
    final ext = parts.length > 1 ? parts.last : '';
    final nameWithoutExt = parts.first;
    final words = nameWithoutExt.split(RegExp(r'[_\-\s]'));
    final shortWords =
        words.length > 3 ? words.sublist(words.length - 3) : words;
    return '${shortWords.join(' ')}${ext.isNotEmpty ? '.$ext' : ''}';
  }
}
