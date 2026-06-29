Here is a file in my Flutter app that contains a __ that is meant for __:


```dart

```

Please write a __ test to test the functionality in this file.

## What to test:

## What not to test:


## Testing rules:
* **Running Tests:** To run tests, use the `run_tests` tool if it is available,
  otherwise use `flutter test`.
* **Unit Tests:** Use `package:test` for unit tests.
* **Widget Tests:** Use `package:flutter_test` for widget tests.
* **Integration Tests:** Use `package:integration_test` for integration tests.
* **Assertions:** Prefer using `package:checks` for more expressive and readable
  assertions over the default `matchers`.

### Testing Best practices
* **Convention:** Follow the Arrange-Act-Assert (or Given-When-Then) pattern.
* **Unit Tests:** Write unit tests for domain logic, data layer, and state
  management.
* **Widget Tests:** Write widget tests for UI components.
* **Integration Tests:** For broader application validation, use integration
  tests to verify end-to-end user flows.
* **integration_test package:** Use the `integration_test` package from the
  Flutter SDK for integration tests. Add it as a `dev_dependency` in
  `pubspec.yaml` by specifying `sdk: flutter`.
* **Mocks:** Prefer fakes or stubs over mocks. If mocks are absolutely
  necessary, use `mockito` or `mocktail` to create mocks for dependencies. While
  code generation is common for state management (e.g., with `freezed`), try to
  avoid it for mocks.
* **Coverage:** Aim for high test coverage.


--------------- For An Agent ------------------

Write a unit/widget/integration test file in dart to test the functionality of " path_to_test ". Follow the appropriate testing rules as described in the directory @.cursor\rules\testing/.
For the given files, test the following things:
- ...
Avoid testing:
- ...
After creating the test, run it, and it fails because of a problem regarding the test, fix the test, but if it fails because of a problem withing the codebase itself so that it doesn't satisfy the conditions of the test, tell be about the problem, what causes it, and suggest a fix. Write the test under [path_of_test].