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
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Login Gagal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(response.message, style: const TextStyle(fontSize: 14)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A1E2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 🔥 INI KUNCINYA
      backgroundColor: const Color(0xFF7A1E2D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -60),
                        child: Image.asset(
                          'assets/images/Whoosh_Member_of_KAI.png',
                          width: 250,
                          height: 250,
                        ),
                      ),

                      const SizedBox(height: 25),

                      MyTextField(
                        controller: _controller.usernameController,
                        hintText: 'username',
                        obscureText: false,
                      ),

                      const SizedBox(height: 10),

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

                      MyButton(onTap: signUserIn),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
