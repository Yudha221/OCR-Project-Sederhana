import 'package:flutter/material.dart';

class StatusColors {
  static final Map<String, Color> ticketOrigin = {
    "Tiket Orisinal": Colors.green,
    "Ticket Baru": Colors.blue,
  };

  static Color getTicketOriginColor(String origin) {
    return ticketOrigin[origin] ?? Colors.grey;
  }
}
