import 'package:flutter/material.dart';
import 'package:page/auth/authentication_service.dart';
import 'package:page/component/input_fild.dart';
import 'package:page/pages/home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:page/pages/welcome_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final authenticatio_service = AuthenticationService();
  final supabase = Supabase.instance.client;

  Future<void> _nativeGoogleSignIn() async {
    /// TODO: update the Web client ID with your own.
    ///
    /// Web Client ID that you registered with Google Cloud.
    const webClientId =
        '858842664598-o10gk4qr5qlet1hte3jackoinmj3jfrm.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    try {
      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (supabase.auth.currentSession != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }

      print("Google Sign-In successful!");
      print("Supabase Session: ${response.session}");
    } catch (e) {
      print("Google Sign-In Error: $e");
    }
  }

  void login() async {
    final email = userNameController.text;
    final password = passwordController.text;
    try {
      final response = await authenticatio_service.signInWithEmailAndPassword(
        email,
        password,
      );

      if (response.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login successful!",
              style: TextStyle(color: Colors.green),
            ),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login failed. Please try again.",
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          content: Text(
            "Error: $e",
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("lib/asset/profile.png"),
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "WELCOME BACK",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 10),
                Text(
                  "your Day is Here!!!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 25),
                InputFiled(
                  controller: userNameController,
                  hintText: "Email Address",
                ),
                InputFiled(
                  controller: passwordController,
                  hintText: "password",
                  obscure: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 220),
                  child: GestureDetector(
                    child: Text(
                      "Forget password",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => login(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            "LogIn",
                            style: TextStyle(
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 135),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have account? ",
                        children: [
                          TextSpan(
                            text: "Register",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 50),
                GestureDetector(
                  onTap: _nativeGoogleSignIn,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.asset("lib/asset/google.png", width: 30),
                          SizedBox(width: 10),
                          Text("SignIn with Google"),
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
    );
  }
}
