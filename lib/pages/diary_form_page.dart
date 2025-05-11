import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:page/theme/theme_provider.dart';

class DiaryFormPage extends StatefulWidget {
  const DiaryFormPage({super.key});

  @override
  State<DiaryFormPage> createState() => _DiaryFormPageState();
}

class _DiaryFormPageState extends State<DiaryFormPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedMood;
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<Map<String, String>> _moods = [
    {'name': 'happy', 'emoji': '😊'},
    {'name': 'sad', 'emoji': '😢'},
    {'name': 'neutral', 'emoji': '😐'},
    {'name': 'excited', 'emoji': '🎉'},
    {'name': 'tired', 'emoji': '😴'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    bool hasPermission = true;
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      hasPermission = status.isGranted;
    } else if (source == ImageSource.gallery) {
      // Modern Android/iOS may not require storage permission for gallery access
      final status = await Permission.photos.request();
      hasPermission = status.isGranted;
    }

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            source == ImageSource.camera
                ? 'Camera permission denied'
                : 'Gallery permission denied',
          ),
        ),
      );
      return;
    }

    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _uploadDiaryEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? base64Image;
      if (_image != null) {
        final imageBytes = await _image!.readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
      }

      final uuid = Uuid();
      final diaryId = uuid.v4();

      final entry = {
        'id': diaryId,
        'title': _titleController.text,
        'text': _contentController.text,
        'mood': _selectedMood,
        'image': base64Image,
        'day': DateFormat('EEEE').format(_selectedDate),
        'time': _selectedTime.format(context),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response =
          await _supabase.from('info').insert(entry).select().single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: const Text('Diary entry uploaded successfully!'),
          ),
        );
        Navigator.of(context).pop(response); // Return the new entry
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Clear'),
            content: const Text('Are you sure you want to clear all fields?'),
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
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _image = null;
                    _titleController.clear();
                    _contentController.clear();
                    _selectedMood = null;
                    _selectedDate = DateTime.now();
                    _selectedTime = TimeOfDay.now();
                  });
                },
                child: Text(
                  'Clear',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Theme(
          data: themeProvider.themeData,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Add Diary Entry'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _uploadDiaryEntry,
                  tooltip: 'Save Entry',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _clearForm,
                  tooltip: 'Clear Form',
                ),
              ],
            ),
            body:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    )
                    : AnimationLimiter(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
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
                                Text(
                                  'Image for Your Day',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          () => _pickImage(ImageSource.gallery),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Gallery'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed:
                                          () => _pickImage(ImageSource.camera),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Camera'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  child:
                                      _image != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              _image!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                    ),
                                                  ),
                                            ),
                                          )
                                          : const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.image, size: 50),
                                                Text('Tap to select an image'),
                                              ],
                                            ),
                                          ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Mood for Your Day',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      _moods.map((mood) {
                                        return ChoiceChip(
                                          label: Text(
                                            '${mood['emoji']} ${mood['name']!.capitalize()}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                          selected:
                                              _selectedMood == mood['name'],
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedMood =
                                                  selected
                                                      ? mood['name']
                                                      : null;
                                            });
                                          },
                                          selectedColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Title for Your Day',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter title',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Describe Your Day',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _contentController,
                                  decoration: InputDecoration(
                                    hintText: 'Describe your day',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 5,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter some content';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Select Day',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _selectDate,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  child: Text(
                                    'Day: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Select Time',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _selectTime,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  child: Text(
                                    'Time: ${_selectedTime.format(context)}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
