import 'package:flutter/material.dart';

Future<List<String>?> promptFields(
    BuildContext context, String title, List<String> labels) async {
  final ctrls = [for (final _ in labels) TextEditingController()];
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (int i = 0; i < labels.length; i++)
            TextField(controller: ctrls[i], decoration: InputDecoration(labelText: labels[i])),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );
  return ok == true ? [for (final c in ctrls) c.text.trim()] : null;
}