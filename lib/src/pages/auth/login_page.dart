import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/login_controller.dart';
import 'package:ocr_project/src/pages/home/home_page.dart';
import 'package:ocr_project/src/widgets/my_button.dart';
import 'package:ocr_project/src/widgets/my_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _controller = LoginController();
  bool _obscurePassword = true;

  Future<void> signUserIn() async {
    final response = await _controller.login();

    if (response.code == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 🔥 INI KUNCINYA
      backgroundColor: const Color(0xFF7A1E2D),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // LOGO (TETAP)
                Image.asset(
                  'assets/images/Whoosh_Member_of_KAI.png',
                  width: 250,
                  height: 250,
                ),

                // TITLE (TETAP)
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: const Text(
                    'Welcome Back to FWC',
                    style: TextStyle(color: Colors.white, fontSize: 26),
                  ),
                ),

                const SizedBox(height: 25),

                // USERNAME
                MyTextField(
                  controller: _controller.usernameController,
                  hintText: 'username',
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // PASSWORD
                MyTextField(
                  controller: _controller.passwordController,
                  hintText: 'password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // BUTTON
                MyButton(onTap: signUserIn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
