import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:page/pages/diary_detail_page.dart';
import 'package:page/pages/diary_form_page.dart';
import 'package:page/pages/login_page.dart';
import 'package:page/pages/mood_trend_page.dart';
import 'package:page/theme/theme_data.dart';
import 'package:page/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  bool _isLoading = false;
  bool _isGridView = false;
  Set<int> expandedEntries = {};
  String _searchQuery = '';
  String? _selectedMood;
  String _sortOption = 'Date';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        _applyFiltersAndSort();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading entries: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDiaryEntry(String entryId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('info').delete().eq('id', entryId);
      _fetchDiaryEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
    }
  }

  void _showDeleteDialog(String entryId) {
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
                  await _deleteDiaryEntry(entryId);
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

  void _shareEntry(Map<String, dynamic> entry) {
    final text =
        '${entry['title']}\n${entry['text']}\nMood: ${entry['mood']}\nCreated: ${entry['created_at']}';
    Share.share(text, subject: entry['title']);
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup initiated (placeholder)')),
    );
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

  void _filterEntries(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    var filtered =
        _entries.where((entry) {
          final title = entry['title']?.toLowerCase() ?? '';
          final text = entry['text']?.toLowerCase() ?? '';
          final mood = entry['mood']?.toLowerCase() ?? '';
          final matchesSearch =
              title.contains(_searchQuery.toLowerCase()) ||
              text.contains(_searchQuery.toLowerCase()) ||
              mood.contains(_searchQuery.toLowerCase());
          final matchesMood =
              _selectedMood == null || entry['mood'] == _selectedMood;
          final matchesDate =
              _selectedDay == null ||
              isSameDay(DateTime.parse(entry['created_at']), _selectedDay!);
          return matchesSearch && matchesMood && matchesDate;
        }).toList();

    if (_sortOption == 'Date') {
      filtered.sort(
        (a, b) => DateTime.parse(
          b['created_at'],
        ).compareTo(DateTime.parse(a['created_at'])),
      );
    } else if (_sortOption == 'Title') {
      filtered.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
    } else if (_sortOption == 'Mood') {
      filtered.sort((a, b) => (a['mood'] ?? '').compareTo(b['mood'] ?? ''));
    }

    _filteredEntries = filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(ThemeModes().lightMode),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Theme(
            data: themeProvider.themeData,
            child: Scaffold(
              extendBody: true, // Ensure FAB is not obscured by body content
              body: SafeArea(
                child: NestedScrollView(
                  headerSliverBuilder:
                      (context, innerBoxIsScrolled) => [
                        SliverAppBar(
                          expandedHeight: 200,
                          floating: true,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: const Text('My Diary'),
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(context).colorScheme.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(
                                _isGridView ? Icons.list : Icons.grid_view,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _isGridView = !_isGridView,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.mood),
                              onPressed:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              MoodTrendPage(entries: _entries),
                                    ),
                                  ),
                            ),
                            IconButton(
                              icon: Icon(
                                themeProvider.themeData.brightness ==
                                        Brightness.light
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                              ),
                              onPressed: () => themeProvider.toggleTheme(),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'Backup') {
                                  _backupData();
                                } else if (value == 'Logout') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'Backup',
                                      child: Text('Backup Data'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Logout',
                                      child: Text('Logout'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ],
                  body: RefreshIndicator(
                    onRefresh: _fetchDiaryEntries,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search entries...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onChanged: _filterEntries,
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                hint: const Text('Mood'),
                                value: _selectedMood,
                                items:
                                    [
                                          null,
                                          'happy',
                                          'sad',
                                          'neutral',
                                          'excited',
                                          'tired',
                                        ]
                                        .map(
                                          (mood) => DropdownMenuItem(
                                            value: mood,
                                            child: Text(
                                              StringExtension(
                                                    mood,
                                                  )?.capitalize() ??
                                                  'All Moods',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMood = value;
                                    _applyFiltersAndSort();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DropdownButton<String>(
                            value: _sortOption,
                            isExpanded: true,
                            items:
                                ['Date', 'Title', 'Mood']
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option,
                                        child: Text('Sort by $option'),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _sortOption = value!;
                                _applyFiltersAndSort();
                              });
                            },
                          ),
                        ),
                        ExpansionTile(
                          title: const Text('Calendar View'),
                          children: [
                            TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate:
                                  (day) => isSameDay(_selectedDay, day),
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                  _applyFiltersAndSort();
                                });
                              },
                            ),
                          ],
                        ),
                        Expanded(
                          child:
                              _isLoading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                  )
                                  : _filteredEntries.isEmpty
                                  ? const Center(
                                    child: Text('No diary entries yet.'),
                                  )
                                  : AnimationLimiter(
                                    child:
                                        _isGridView
                                            ? GridView.builder(
                                              padding: const EdgeInsets.all(16),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing: 16,
                                                    mainAxisSpacing: 16,
                                                    childAspectRatio: 0.75,
                                                  ),
                                              itemCount:
                                                  _filteredEntries.length,
                                              itemBuilder:
                                                  (
                                                    context,
                                                    index,
                                                  ) => AnimationConfiguration.staggeredGrid(
                                                    position: index,
                                                    columnCount: 2,
                                                    duration: const Duration(
                                                      milliseconds: 375,
                                                    ),
                                                    child: ScaleAnimation(
                                                      child: FadeInAnimation(
                                                        child: _buildEntryCard(
                                                          index,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            : ListView.builder(
                                              padding: const EdgeInsets.all(16),
                                              itemCount:
                                                  _filteredEntries.length,
                                              itemBuilder:
                                                  (
                                                    context,
                                                    index,
                                                  ) => AnimationConfiguration.staggeredList(
                                                    position: index,
                                                    duration: const Duration(
                                                      milliseconds: 375,
                                                    ),
                                                    child: SlideAnimation(
                                                      verticalOffset: 50.0,
                                                      child: FadeInAnimation(
                                                        child: _buildEntryCard(
                                                          index,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  debugPrint('FAB pressed'); // Debug log to confirm tap
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DiaryFormPage(),
                    ),
                  );
                  _fetchDiaryEntries();
                },
                backgroundColor: Theme.of(context).colorScheme.secondary,
                tooltip: 'Add Diary Entry',
                child: const Icon(Icons.add, size: 30),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _filteredEntries[index];
    bool isExpanded = expandedEntries.contains(index);
    Uint8List? imageBytes;
    if (entry['image'] != null && entry['image'].isNotEmpty) {
      String imageStr = entry['image'];
      if (imageStr.startsWith('data:image')) {
        final base64Str = imageStr.split(',').last;
        try {
          imageBytes = base64Decode(base64Str);
        } catch (e) {
          debugPrint("Image decoding error: $e");
        }
      }
    }

    return Hero(
      tag: 'entry-${entry['id']}',
      child: GestureDetector(
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DiaryDetailPage(entry: entry),
              ),
            ),
        onLongPress: () => _showDeleteDialog(entry['id'].toString()),
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  _getMoodColor(entry['mood']),
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['day'] ?? 'No day set',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: () => _shareEntry(entry),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          Text(
                            _getMoodEmoji(entry['mood']),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    entry['title'] ?? 'No Title',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      entry['text'] ?? 'No Content',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: isExpanded ? null : 3,
                      overflow:
                          isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                    ),
                  ),
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
                        isExpanded ? 'Less' : 'More',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Created: ${entry['created_at'].toString().split('T').first}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
