import 'package:flutter/material.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/preview_image.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'dart:ui';

class ImageMessageBubble extends StatefulWidget {
  final String imageUrl;
  final bool isMe;
  final String timestamp;
  final bool uploading;
  final bool sent;
  final VoidCallback? onImageLoaded;

  const ImageMessageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
    required this.timestamp,
    this.uploading = false,
    this.sent = false,
    this.onImageLoaded,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  bool isDownloading = false;
  bool isDownloaded = false;
  double progress = 0.0;
  late File file;

  @override
  void initState() {
    super.initState();
    _initFile();
  }

  Future<void> _initFile() async {
    file = await _getCachedFile(widget.imageUrl);
    if (await file.exists()) {
      setState(() => isDownloaded = true);
    }
  }

  Future<File> _getCachedFile(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = Uri.parse(url).pathSegments.last;
    return File('${dir.path}/$name');
  }

  Future<void> _downloadImage() async {
    try {
      setState(() {
        isDownloading = true;
        progress = 0.0;
      });

      final response = await http.Client()
          .send(http.Request('GET', Uri.parse(widget.imageUrl)));
      final contentLength = response.contentLength ?? 1;
      final List<int> bytes = [];

      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          setState(() => progress = bytes.length / contentLength);
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          setState(() {
            isDownloading = false;
            isDownloaded = true;
          });
        },
        onError: (_) => setState(() => isDownloading = false),
        cancelOnError: true,
      );
    } catch (_) {
      setState(() => isDownloading = false);
    }
  }

  void _handleTap() {
    if (isDownloaded) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewImage(imageUrl: file.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: isDownloaded ? _handleTap : null,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isDownloaded
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            // Show blurred preview of the actual image
                            Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black.withOpacity(0.2),
                              colorBlendMode: BlendMode.darken,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(color: Colors.grey[300]);
                              },
                              errorBuilder: (context, _, __) =>
                                  Container(color: Colors.grey[300]),
                            ),
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: Colors.black.withOpacity(0.2),
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            // Center content
                            isDownloading
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${(progress * 100).toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download_rounded,
                                            size: 36, color: Colors.white),
                                        onPressed: _downloadImage,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.timestamp,
                    style: const TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 10)),
                const SizedBox(width: 4),
                if (widget.uploading)
                  const Icon(Icons.access_time, size: 12, color: Colors.grey)
                else if (widget.sent)
                  const Icon(Icons.done_all, size: 14, color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
