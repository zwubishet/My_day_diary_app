import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'diary_edit_page.dart';

class DiaryDetailPage extends StatefulWidget {
  final Map<String, dynamic> entry;

  const DiaryDetailPage({super.key, required this.entry});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late Map<String, dynamic> entry;

  @override
  void initState() {
    super.initState();
    entry = Map<String, dynamic>.from(widget.entry);
  }

  Future<void> _refreshEntry(Map<String, dynamic> updatedEntry) async {
    setState(() {
      entry = updatedEntry;
    });
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (entry['image'] != null && entry['image'].isNotEmpty) {
      String imageStr = entry['image'];
      if (imageStr.startsWith('data:image')) {
        final base64Str = imageStr.split(',').last;
        try {
          imageBytes = base64Decode(base64Str);
        } catch (e) {
          print("Image decoding error: $e");
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Diary Details"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final updatedEntry = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DiaryEditPage(entry: entry),
                ),
              );

              if (updatedEntry != null) {
                _refreshEntry(updatedEntry);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Simple refresh effect
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['title'] ?? 'No Title',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),

                SizedBox(height: 10),
                Text(
                  entry['text'] ?? 'No Content',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                Text(
                  'Created At: ${entry['created_at'].toString().split('T').first}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
