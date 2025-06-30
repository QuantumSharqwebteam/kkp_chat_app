import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DocumentViewer extends StatefulWidget {
  final String documentUrl;

  const DocumentViewer({super.key, required this.documentUrl});

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  Future<void> _downloadAndOpenFile() async {
    try {
      final response = await http.get(Uri.parse(widget.documentUrl));
      final bytes = response.bodyBytes;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_file.xlsx');
      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Viewer'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _downloadAndOpenFile,
          child: const Text('Open Document'),
        ),
      ),
    );
  }
}
