import 'package:flutter/material.dart';

class Announcement {
  final int id;
  final String subjectCode;
  final Color color;
  final String type;
  final String title;
  final String body;
  final String time;
  final String? tag;

  const Announcement({
    required this.id,
    required this.subjectCode,
    required this.color,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.tag,
  });
}
