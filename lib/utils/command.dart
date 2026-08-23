import 'package:articly/utils/my_snack_bar.dart';
import 'package:flutter/cupertino.dart';

class Command {
  Command({
    this.activated = false,
    this.running = false,
    this.error,
    this.completed = false,
  });

  bool activated;
  bool running;

  String? error;
  bool get hasError => error != null;

  bool completed; // if the action completed successfully (no errors)

  /// Doesn't include error handling
  // Future<void> execute() async {
  //   await _action();
  // }

  void start() {
    activated = true;
    running = true;
    error = null;
    completed = false;
  }

  void finish([String? errorMessage]) {
    running = false;
    error = errorMessage;
    completed = errorMessage == null ? true : false;
    // set completed based on error message. If the error is null, the action completed, otherwise it had not.
  }

  void successful() {
    running = false;
    error = null;
    completed = true;
  }

  void problem(String errorMessage) {
    running = false;
    error = errorMessage;
    completed = false;
  }

  void clear() {
    running = false;
    error = null;
    completed = false;
  }

  /// Shows success or error snack bar based of the command's fields
  /// If receives a successMsg, displays it in case of success. Otherwise, displays nothing
  /// If receives errorMsg, shows it instead of the known error attribute
  void showSuccessOrErrorSnackBar(
    BuildContext context, {
    String? successMsg,
    String? errorMsg,
  }) {
    final String? finalError = errorMsg ?? error;

    if (successMsg != null && completed && finalError == null) {
      MySnackBar(context, message: successMsg).show();
      return;
    }

    if (finalError != null && !completed) {
      MySnackBar(context, message: finalError).show();
      return;
    }

    return;
  }
}
