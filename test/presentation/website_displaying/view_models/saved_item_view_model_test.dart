// import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
// import 'package:checks/checks.dart';
// import 'package:test/test.dart';

// void main() {
//   group('SavedItemViewModel', () {
//     late SavedItemViewModel viewModel;
//     late bool? launchResult;
//     late List<String> clipboardContents;

//     SavedItemViewModel createViewModel({
//       String? title,
//       Uri? uri,
//       String? notes,
//     }) {
//       return SavedItemViewModel(title: title, uri: uri, notes: notes);
//     }

//     final uri = Uri.parse('https://example.com');

//     setUp(() {
//       launchResult = null;
//       clipboardContents = <String>[];
//       viewModel = createViewModel(
//         title: 'Test Title',
//         uri: uri,
//         notes: 'Test Notes',
//       );
//     });

//     group('constructor', () {
//       test('builds the object correctly and sets a Command to openUrl', () {
//         check(viewModel.title).equals('Test Title');
//         check(viewModel.uri).equals(Uri.parse('https://example.com'));
//         check(viewModel.notes).equals('Test Notes');
//         check(viewModel.openUrlCommand).isNotNull();
//       });
//     });

//     group('toggleExpand', () {
//       test('switches the value of isExpanded and notifies listeners', () {
//         var notified = false;
//         viewModel.addListener(() {
//           notified = true;
//         });

//         viewModel.toggleExpand();

//         check(viewModel.isExpanded).isTrue();
//         check(notified).isTrue();

//         notified = false;
//         viewModel.toggleExpand();

//         check(viewModel.isExpanded).isFalse();
//         check(notified).isTrue();
//       });
//     });

//     group('copyContents', () {
//       test(
//         'copies a formatted string with title, notes, and url separated by blank lines',
//         () async {
//           await viewModel.copyContents();

//           check(clipboardContents.length).equals(1);
//           check(
//             clipboardContents.first,
//           ).equals('Test Title\n\nTest Notes\n\n(https://example.com)');
//         },
//       );

//       test('omits a missing part without adding extra blank lines', () async {
//         viewModel = createViewModel(
//           title: null,
//           uri: Uri.parse('https://example.com'),
//           notes: null,
//         );

//         await viewModel.copyContents();

//         check(clipboardContents.length).equals(1);
//         check(clipboardContents.first).equals('(https://example.com)');
//       });

//       test('handles empty strings as missing', () async {
//         viewModel = createViewModel(
//           title: '',
//           uri: Uri.parse('https://example.com'),
//           notes: '',
//         );

//         await viewModel.copyContents();

//         check(clipboardContents.length).equals(1);
//         check(clipboardContents.first).equals('(https://example.com)');
//       });
//     });

//     group('isUrlValid', () {
//       test('returns true for a valid https url', () {
//         check(viewModel.isUrlValid(Uri.parse('https://example.com'))).isTrue();
//       });

//       test('returns true for a valid http url', () {
//         check(viewModel.isUrlValid(Uri.parse('http://example.com'))).isTrue();
//       });

//       test('returns false when uri is null', () {
//         check(viewModel.isUrlValid(null)).isFalse();
//       });

//       test('returns false when uri has no scheme', () {
//         check(viewModel.isUrlValid(Uri(host: 'example.com'))).isFalse();
//       });

//       test('returns false when the scheme is not http or https', () {
//         check(viewModel.isUrlValid(Uri.parse('ftp://example.com'))).isFalse();
//       });

//       test('returns false when host is empty', () {
//         check(viewModel.isUrlValid(Uri(scheme: 'https'))).isFalse();
//       });
//     });

//     group('openUrl via openUrl.execute', () {
//       test(
//         'sets running to true, error to null, completed to false, and notifies listeners',
//         () async {
//           var notified = false;
//           viewModel.addListener(() {
//             notified = true;
//           });

//           launchResult = true;
//           viewModel.openUrl();

//           check(viewModel.openUrlCommand.running).isFalse();
//           check(notified).isTrue();
//         },
//       );

//       test(
//         'if the uri is invalid, sets running to false, completed to false, error message, and notifies listeners',
//         () async {
//           viewModel = createViewModel(
//             title: 'Title',
//             uri: Uri(scheme: 'http'),
//             notes: 'Notes',
//           );

//           var notified = false;
//           viewModel.addListener(() {
//             notified = true;
//           });

//           await viewModel.openUrl();

//           check(viewModel.openUrlCommand.running).isFalse();
//           check(viewModel.openUrlCommand.completed).isFalse();
//           check(
//             viewModel.openUrlCommand.error,
//           ).equals("Can't open the webpage because the url isn't valid");
//           check(viewModel.openUrlCommand.hasError).isTrue();
//           check(notified).isTrue();
//         },
//       );

//       test(
//         'if launching the url is not successful, sets running to false, completed to false, error message, and notifies listeners',
//         () async {
//           launchResult = false;

//           var notified = false;
//           viewModel.addListener(() {
//             notified = true;
//           });

//           await viewModel.openUrl();

//           check(viewModel.openUrlCommand.running).isFalse();
//           check(viewModel.openUrlCommand.completed).isFalse();
//           check(viewModel.openUrlCommand.error).equals("Can't open the url");
//           check(viewModel.openUrlCommand.hasError).isTrue();
//           check(notified).isTrue();
//         },
//       );

//       test(
//         'on success, sets running to false, completed to true, error to null, and notifies listeners',
//         () async {
//           launchResult = true;

//           var notified = false;
//           viewModel.addListener(() {
//             notified = true;
//           });

//           await viewModel.openUrl();

//           check(viewModel.openUrlCommand.running).isFalse();
//           check(viewModel.openUrlCommand.completed).isTrue();
//           check(viewModel.openUrlCommand.error).isNull();
//           check(viewModel.openUrlCommand.hasError).isFalse();
//           check(notified).isTrue();
//         },
//       );
//     });
//   });
// }
