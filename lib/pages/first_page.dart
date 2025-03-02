import 'package:flutter/material.dart';
import 'package:page/pages/login_page.dart';
import 'package:page/pages/register_page.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("My Day Diary"),
            Image.asset("lib/asset/jourrnaling.png"),
            Text(
              "Welcome to Your Personal Space – Where Every Thought Matters.",
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: Colors.black54, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Text("SignUp"),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: Container(child: Text("SignUp")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
