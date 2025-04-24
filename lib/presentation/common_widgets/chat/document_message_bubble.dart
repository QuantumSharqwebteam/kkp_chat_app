import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DocumentMessageBubble extends StatefulWidget {
  final String documentUrl;
  final bool isMe;
  final String timestamp;

  const DocumentMessageBubble({
    super.key,
    required this.documentUrl,
    required this.isMe,
    required this.timestamp,
  });

  @override
  State<DocumentMessageBubble> createState() => _DocumentMessageBubbleState();
}

class _DocumentMessageBubbleState extends State<DocumentMessageBubble>
    with SingleTickerProviderStateMixin {
  bool isDownloading = false;
  bool isDownloaded = false;
  bool hasError = false;
  double progress = 0.0;
  late File file;
  late AnimationController _animController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initFile();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.lightBlueAccent,
    ).animate(_animController);
  }

  Future<void> _initFile() async {
    file = await _getCachedFile(widget.documentUrl);
    if (await file.exists()) {
      setState(() => isDownloaded = true);
    }
  }

  Future<File> _getCachedFile(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(url).pathSegments.last;
    return File('${dir.path}/$fileName');
  }

  Future<void> _downloadFile() async {
    try {
      setState(() {
        isDownloading = true;
        progress = 0.0;
        hasError = false;
      });

      final response = await http.Client()
          .send(http.Request('GET', Uri.parse(widget.documentUrl)));
      final contentLength = response.contentLength ?? 1;
      final List<int> bytes = [];

      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          setState(() {
            progress = bytes.length / contentLength;
          });
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          setState(() {
            isDownloading = false;
            isDownloaded = true;
          });
          await OpenFilex.open(file.path);
        },
        onError: (_) {
          setState(() {
            isDownloading = false;
            hasError = true;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        isDownloading = false;
        hasError = true;
      });
    }
  }

  Widget _buildFileTypeIcon() {
    final ext = widget.documentUrl.split('.').last.toLowerCase();
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

  Widget _buildActionIcon() {
    if (isDownloading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) => SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                value: progress,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _colorAnimation.value ?? Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      );
    } else if (hasError) {
      return GestureDetector(
        onTap: _downloadFile,
        child: Icon(Icons.refresh, size: 40, color: Colors.white),
      );
    } else if (!isDownloaded) {
      return GestureDetector(
        onTap: _downloadFile,
        child: Icon(Icons.download, size: 40, color: Colors.white),
      );
    } else {
      return _buildFileTypeIcon();
    }
  }

  void _handleTap() async {
    if (isDownloaded) {
      await OpenFilex.open(file.path);
    } else {
      await _downloadFile();
    }
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

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = Uri.parse(widget.documentUrl).pathSegments.last;
    final shortFileName = _getShortFileName(fileName);

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isMe
                ? AppColors.blue00ABE9
                : AppColors.messageBubbleColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionIcon(),
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
                        color: widget.isMe ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.timestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isMe ? Colors.white70 : Colors.black54,
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
  }
}
