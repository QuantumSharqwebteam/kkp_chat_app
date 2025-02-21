import 'package:flutter/material.dart';

class AttachmentMenu extends StatelessWidget {
  final Function(String) onItemSelected;

  const AttachmentMenu({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> items = [
      {'icon': Icons.image, 'label': 'Photos', 'type': 'photo'},
      {'icon': Icons.camera_alt, 'label': 'Camera', 'type': 'camera'},
      {
        'icon': Icons.insert_drive_file,
        'label': 'Documents',
        'type': 'document'
      },
      {'icon': Icons.videocam, 'label': 'Videos', 'type': 'video'},
      {'icon': Icons.contacts, 'label': 'Contacts', 'type': 'contact'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          return GestureDetector(
            onTap: () => onItemSelected(item['type']),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  child: Icon(item['icon'], color: Colors.blue, size: 30),
                ),
                SizedBox(height: 8),
                Text(item['label'], style: TextStyle(color: Colors.black)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
