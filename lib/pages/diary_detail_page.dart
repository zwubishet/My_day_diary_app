import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:page/pages/diary_edit_page.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:page/theme/theme_data.dart';
import 'package:page/theme/theme_provider.dart';

class DiaryDetailPage extends StatefulWidget {
  final Map<String, dynamic> entry;

  const DiaryDetailPage({super.key, required this.entry});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late Map<String, dynamic> _entry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry; // Directly use widget.entry, no need to copy
  }

  Future<void> _refreshEntry() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response =
          await supabase
              .from('info')
              .select('*')
              .eq('id', _entry['id'])
              .single();

      setState(() {
        _entry = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error refreshing entry: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('info').delete().eq('id', _entry['id']);
      Navigator.of(context).pop(); // Return to previous page after deletion
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: const Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteEntry();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _shareEntry() {
    final text =
        '${_entry['title']}\n${_entry['text']}\nMood: ${_entry['mood']}\nCreated: ${_entry['created_at']}';
    Share.share(text, subject: _entry['title']);
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'neutral':
        return '😐';
      case 'excited':
        return '🎉';
      case 'tired':
        return '😴';
      default:
        return '';
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'happy':
        return Colors.yellow.shade100;
      case 'sad':
        return Colors.blue.shade100;
      case 'neutral':
        return Colors.grey.shade100;
      case 'excited':
        return Colors.orange.shade100;
      case 'tired':
        return Colors.purple.shade100;
      default:
        return Theme.of(context).colorScheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (_entry['image'] != null && _entry['image'].isNotEmpty) {
      String imageStr = _entry['image'];
      if (imageStr.startsWith('data:image')) {
        final base64Str = imageStr.split(',').last;
        try {
          imageBytes = base64Decode(base64Str);
        } catch (e) {
          debugPrint("Image decoding error: $e");
        }
      }
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Theme(
          data: themeProvider.themeData,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Diary Details'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareEntry,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updatedEntry = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DiaryEditPage(entry: _entry),
                      ),
                    );
                    if (updatedEntry != null) {
                      setState(() {
                        _entry = updatedEntry;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showDeleteDialog,
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refreshEntry,
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      )
                      : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: AnimationLimiter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 375),
                                childAnimationBuilder:
                                    (widget) => SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(child: widget),
                                    ),
                                children: [
                                  Hero(
                                    tag: 'entry-${_entry['id']}',
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              _getMoodColor(_entry['mood']),
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _entry['title'] ?? 'No Title',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Mood: ${_getMoodEmoji(_entry['mood'])} ${_entry['mood']?.toString().capitalize() ?? 'No mood set'}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontSize: 16,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (imageBytes != null)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.memory(
                                                  imageBytes,
                                                  width: double.infinity,
                                                  height: 250,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        height: 250,
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            size: 50,
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                              )
                                            else
                                              Container(
                                                height: 250,
                                                decoration: BoxDecoration(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _entry['text'] ?? 'No Content',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Created: ${_entry['created_at'].toString().split('T').first}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            if (_entry['updated_at'] != null)
                                              Text(
                                                'Updated: ${_entry['updated_at'].toString().split('T').first}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.6),
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
