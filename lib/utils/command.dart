class Command {
  Command(this._action);

  bool running = false;

  String? error;
  bool get hasError => error != null;

  bool completed = false; // if the action completed successfully (no errors)

  final Future<void> Function() _action;

  /// Doesn't include error handling
  Future<void> execute() async {
    await _action();
  }

  void start() {
    running = true;
    error = null;
    completed = false;
  }

  void finish(String? errorMessage) {
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
}
