import 'package:flutter/material.dart';
import 'package:page/pages/register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int current_page = 0;

  final image_content = [
    {
      "image": "lib/asset/welcome-back.png",
      "content":
          "Welcome to Your Personal Space – Where Every Thought Matters.",
    },
    {
      "image": "lib/asset/journaling.png",
      "content": "Start Writing. Start Reflecting. Start Growing.",
    },
    {
      "image": "lib/asset/notebook.png",
      "content": "Your Story Begins Here. Let’s Capture Every Moment.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                SizedBox(height: 100),
                Container(
                  height: 250,
                  width: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(image_content[current_page]["image"]!),
                    ),
                  ),
                ),
                Text(
                  image_content[current_page]["content"]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 0
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 0
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 1
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 1
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 2
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 2
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (current_page < image_content.length - 1) {
                        current_page++;
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      }
                    });
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
