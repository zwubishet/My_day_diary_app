import 'package:flutter/material.dart';
import 'package:page/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiaryEditPage extends StatefulWidget {
  final Map<String, dynamic> entry;

  const DiaryEditPage({super.key, required this.entry});

  @override
  State<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends State<DiaryEditPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _textController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.entry['title'] ?? '';
    _textController.text = widget.entry['text'] ?? '';
  }

  /// Function to update entry in Supabase
  Future<void> _updateDiaryEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('info')
          .update({
            'title': _titleController.text,
            'text': _textController.text,
          })
          .eq('id', widget.entry['id']);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry updated successfully!')));

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating entry: $e')));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Entry")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
                validator:
                    (value) => value!.isEmpty ? "Title cannot be empty" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 5,
                validator:
                    (value) =>
                        value!.isEmpty ? "Content cannot be empty" : null,
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
