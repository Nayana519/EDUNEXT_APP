import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

Color hexToColor(String hex) =>
    Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

String timeAgo(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}

String apiError(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['detail'] != null) {
      final detail = d['detail'];
      return detail is String ? detail : 'Invalid input. Check the fields.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'The server is taking too long.';
    }
    return 'Could not reach the server.';
  }
  return e.toString();
}