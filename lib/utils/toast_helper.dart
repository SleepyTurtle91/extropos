import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:universal_io/io.dart';

class ToastHelper {
  static void showToast(
    BuildContext context,
    String message, {
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // For native text-toasts on Android/iOS avoid calling setGravity for
        // the default bottom gravity to prevent the native warning. Only pass
        // gravity if the caller explicitly requests a different one.
        if (gravity != ToastGravity.BOTTOM) {
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: gravity,
            fontSize: 14.0,
          );
        } else {
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            fontSize: 14.0,
          );
        }
      } else {
        // Fallback to SnackBar on other platforms
          final messenger = ScaffoldMessenger.maybeOf(context);
            final hasScaffold = Scaffold.maybeOf(context) != null;
            if (messenger != null && hasScaffold) {
              messenger.showSnackBar(SnackBar(content: Text(message)));
            } else {
            // No Scaffold available in this context (e.g., during tests), fallback to console log
            // or ignore silently
            // ignore: avoid_print
            print('Toast: $message');
          }
      }
    } catch (e) {
      // Fallback: if everything fails, use a snackbar
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      } else {
        // ignore: avoid_print
        print('Toast: $message');
      }
    }
  }
}
