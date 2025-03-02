import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:page/pages/diary_detail_page.dart';
import 'package:page/pages/diary_form_page.dart';
import 'package:page/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  Set<int> expandedEntries = {}; // Track expanded items

  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries();
  }

  /// Function to fetch diary entries
  Future<void> _fetchDiaryEntries() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('info')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _entries = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading entries: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Function to delete a diary entry
  Future<void> _deleteDiaryEntry(String entryId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.from('info').delete().eq('id', entryId);

      if (response == null) {
        throw Exception('No response from Supabase');
      }

      _fetchDiaryEntries(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(String entryId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Entry'),
            content: Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteDiaryEntry(entryId);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Day'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchDiaryEntries),
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => LoginPage()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDiaryEntries,
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
                : _entries.isEmpty
                ? Center(child: Text('No diary entries yet.'))
                : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    bool isExpanded = expandedEntries.contains(index);

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

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DiaryDetailPage(entry: entry),
                          ),
                        );
                      },
                      onLongPress:
                          () => _showDeleteDialog(entry['id'].toString()),
                      child: Card(
                        margin: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry['day'] ?? 'No set',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    entry['time'] ?? 'No set',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
                                entry['title'] ?? 'No Title',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),

                              // Expandable Text Section
                              AnimatedSize(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  entry['text'] ?? 'No Content',
                                  style: TextStyle(fontSize: 16),
                                  maxLines:
                                      isExpanded
                                          ? null
                                          : 3, // Show 3 lines by default
                                  overflow:
                                      isExpanded
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                ),
                              ),

                              // "More" button
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        expandedEntries.remove(index);
                                      } else {
                                        expandedEntries.add(index);
                                      }
                                    });
                                  },
                                  child: Text(
                                    isExpanded ? "Less >>>" : "More >>>",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),

                              Text(
                                'Created At: ${entry['created_at'].toString().split('T').first}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => DiaryFormPage()));
          _fetchDiaryEntries();
        },
        child: Icon(Icons.add, size: 40),
      ),
    );
  }
}
