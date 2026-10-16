import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String code;
  final String name;
  final String teacher;
  final Color color;
  final int unread;

  const Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.teacher,
    required this.color,
    required this.unread,
  });
}
