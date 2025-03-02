import 'package:flutter/material.dart';
import 'package:page/pages/login_page.dart';

import 'package:page/pages/welcome_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null) {
          return LoginPage();
        } else {
          return WelcomePage();
        }
      },
    );
  }
}
