import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade200,

          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),

          // BORDER NORMAL
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // 👈 UJUNG MELENGKUNG
            borderSide: BorderSide.none, // 👈 tanpa garis
          ),

          // BORDER SAAT FOCUS
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // 👈 HARUS SAMA
            borderSide: BorderSide.none,
          ),

          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14, // 👈 tinggi TextField
          ),
        ),
      ),
    );
  }
}
