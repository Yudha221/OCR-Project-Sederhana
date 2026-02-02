import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const MyDrawerTile({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
