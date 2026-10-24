import 'package:flutter/material.dart';

import 'tv_button.dart';

Future<bool> showTvConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认',
}) async {
  final previous = FocusManager.instance.primaryFocus;
  try {
    return await showDialog<bool>(
          context: context,
          requestFocus: true,
          traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TvButton(
                key: const Key('dialog-cancel'),
                label: '取消',
                autofocus: true,
                onPressed: () => Navigator.pop(context, false),
              ),
              TvButton(
                key: const Key('dialog-confirm'),
                label: confirmLabel,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  } finally {
    if (previous?.context != null && previous!.canRequestFocus) {
      previous.requestFocus();
    }
  }
}
