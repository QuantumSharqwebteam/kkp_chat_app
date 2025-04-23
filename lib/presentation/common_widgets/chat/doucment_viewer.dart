import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class DocumentViewer extends StatefulWidget {
  final String documentUrl;

  const DocumentViewer({super.key, required this.documentUrl});

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  String? localPath;
  bool isPdf = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadFile(widget.documentUrl);
  }

  Future<void> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last.split('?').first;
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        localPath = file.path;
        isPdf = file.path.toLowerCase().endsWith('.pdf');
        isLoading = false;
      });

      if (!isPdf) {
        // Open with system app if not PDF
        OpenFilex.open(file.path);
        if (mounted) {
          Navigator.pop(context);
        } // close viewer after launch
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening file: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document Viewer')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isPdf
              ? PDFView(filePath: localPath!)
              : const Center(child: Text('Opening in system viewer...')),
    );
  }
}
