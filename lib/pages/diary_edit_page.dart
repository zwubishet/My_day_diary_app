import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiaryEditPage extends StatefulWidget {
  final Map<String, dynamic> entry;

  const DiaryEditPage({super.key, required this.entry});

  @override
  State<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends State<DiaryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  File? image;
  String? base64ImageString;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  String? selectedMood;
  bool _isUpdating = false;

  final List<Map<String, String>> moods = [
    {'name': 'happy', 'emoji': '😊'},
    {'name': 'sad', 'emoji': '😢'},
    {'name': 'neutral', 'emoji': '😐'},
    {'name': 'excited', 'emoji': '🎉'},
    {'name': 'tired', 'emoji': '😴'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.entry['title'] ?? '';
    _textController.text = widget.entry['text'] ?? '';
    base64ImageString = widget.entry['image'];
    selectedDate = DateTime.parse(widget.entry['created_at']);
    selectedTime = _parseTime(
      widget.entry['time'] ?? TimeOfDay.now().format(context),
    );
    selectedMood = widget.entry['mood'];
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      final hourMinute = parts[1].split(' ');
      final hour = int.parse(parts[0]);
      final minute = int.parse(hourMinute[0]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Future<void> _updateDiaryEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      // Convert new image to Base64 if selected
      if (image != null) {
        final imageBytes = await image!.readAsBytes();
        base64ImageString =
            "data:image/jpeg;base64,${base64Encode(imageBytes)}";
      }

      final supabase = Supabase.instance.client;
      final updatedData = {
        'title': _titleController.text,
        'text': _textController.text,
        'image': base64ImageString,
        'day': DateFormat('EEEE').format(selectedDate),
        'time': selectedTime.format(context),
        'mood': selectedMood,
        'created_at': selectedDate.toUtc().toIso8601String(),
      };

      await supabase
          .from('info')
          .update(updatedData)
          .eq('id', widget.entry['id']);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry updated successfully!')));

      // Return updated entry to DiaryDetailPage
      Navigator.pop(context, {'id': widget.entry['id'], ...updatedData});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating entry: $e')));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Text('Camera permission denied'),
          ),
        );
        return;
      }
    } else if (source == ImageSource.gallery) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Text('Storage permission denied'),
          ),
        );
        return;
      }
    }

    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      final file = File(pickedImage.path);
      setState(() {
        image = file;
      });
    }
  }

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Entry"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isUpdating ? null : _updateDiaryEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Image for Your Day",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      pickImage(ImageSource.gallery);
                    },
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary,
                      ),
                      padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                    ),
                    child: Text(
                      "Gallery",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      pickImage(ImageSource.camera);
                    },
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary,
                      ),
                      padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                    ),
                    child: Text(
                      "Camera",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              image != null
                  ? Image.file(image!, height: 200, fit: BoxFit.cover)
                  : base64ImageString != null
                  ? Image.memory(
                    base64Decode(base64ImageString!.split(',').last),
                    height: 200,
                    fit: BoxFit.cover,
                  )
                  : Text("Selected image will appear here"),
              SizedBox(height: 16),
              const Text(
                "Mood for Your Day",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children:
                    moods.map((mood) {
                      return ChoiceChip(
                        label: Text(mood['emoji']!),
                        selected: selectedMood == mood['name'],
                        onSelected: (selected) {
                          setState(() {
                            selectedMood = selected ? mood['name'] : null;
                          });
                        },
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
                validator:
                    (value) => value!.isEmpty ? "Title cannot be empty" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 5,
                validator:
                    (value) =>
                        value!.isEmpty ? "Content cannot be empty" : null,
              ),
              SizedBox(height: 16),
              const Text(
                "Select Day",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: selectDate,
                child: Text(
                  'Select Day: ${selectedDate.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                "Select Time",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: selectTime,
                child: Text(
                  'Select Time: ${selectedTime.format(context)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUpdating ? null : _updateDiaryEntry,
                child:
                    _isUpdating
                        ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onSecondary,
                        )
                        : Text(
                          "Update",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
