import 'package:flutter/material.dart';

Widget rowText(
  String label,
  String value, {
  Color? labelColor, // 👈 TAMBAHAN
  Color? valueColor,
  bool isBold = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: labelColor ?? Colors.black, // 👈 LABEL COLOR
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}
