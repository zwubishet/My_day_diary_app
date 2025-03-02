import 'dart:convert'; // Import for Base64 encoding/decoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Import for UUID generation

class DiaryFormPage extends StatefulWidget {
  const DiaryFormPage({super.key});

  @override
  State<DiaryFormPage> createState() => _DiaryFormPageState();
}

class _DiaryFormPageState extends State<DiaryFormPage> {
  File? image;
  String? base64ImageString; // Store Base64 encoded string
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> uploadDiaryEntry() async {
    if (image == null ||
        titleController.text.isEmpty ||
        contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select an image')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Convert image to Base64 string
      final imageBytes = await image!.readAsBytes();
      base64ImageString =
          "data:image/jpeg;base64,${base64Encode(imageBytes)}"; // Add prefix
      print(
        "Base64 Image (before storing): ${base64ImageString!.substring(0, 50)}...",
      );

      // Generate a UUID for the entry
      var uuid = Uuid();
      String diaryId = uuid.v4(); // Generate a version 4 UUID

      // Store data in Supabase
      final response = await supabase.from('info').insert({
        'id': diaryId, // Add UUID field
        'title': titleController.text,
        'text': contentController.text,
        'image': base64ImageString, // Store Base64 image
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'day': DateFormat('EEEE').format(selectedDate), // Store day
        'time': selectedTime.format(context), // Store time
      });

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diary entry uploaded successfully!')),
        );

        setState(() {
          image = null;
          base64ImageString = null;
          titleController.clear();
          contentController.clear();
        });
      } else {
        throw Exception(response.error!.message);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        isLoading = false;
      });
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
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          GestureDetector(onTap: uploadDiaryEntry, child: Icon(Icons.save)),
          SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Confirm Clear'),
                      content: Text(
                        'Are you sure you want to clear all fields?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              image = null;
                              base64ImageString = null;
                              titleController.clear();
                              contentController.clear();
                            });
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            },
            child: Icon(Icons.delete),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                    ? Image.file(image!)
                    : base64ImageString != null
                    ? Image.memory(base64Decode(base64ImageString!))
                    : Text("Selected image will appear here"),
                const SizedBox(height: 10),
                const Text(
                  "Title for Your Day",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(hintText: "Enter title"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Describe Your Day",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: "Describe your day"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select Day",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: selectDate,
                  child: Text(
                    'Select Day: ${selectedDate.toLocal()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select Time",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  style: ButtonStyle(),
                  onPressed: selectTime,
                  child: Text(
                    'Select Time: ${selectedTime.format(context)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
