import 'package:flutter/material.dart';

class InputFiled extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscure;

  const InputFiled({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscure = false,
  });

  @override
  State<InputFiled> createState() => _InputFiledState();
}

class _InputFiledState extends State<InputFiled> {
  bool _showHint = true;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _showHint = widget.controller.text.isEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: TextField(
          obscureText: widget.obscure,
          showCursor: true,
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: _showHint ? widget.hintText : null,
            border: InputBorder.none,

            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            hintStyle: TextStyle(color: Colors.grey), // Hint text color
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ), // Text color
        ),
      ),
    );
  }
}
