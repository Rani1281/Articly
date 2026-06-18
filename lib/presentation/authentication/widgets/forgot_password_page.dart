import 'package:articly/data/services/auth_service.dart';
import 'package:articly/presentation/authentication/widgets/auth_text_field.dart';
import 'package:articly/presentation/authentication/widgets/cooldown_widget.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, String? email}) : _passedEmail = email;

  final String? _passedEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late TextEditingController _emailController;

  String? _emailErrorMsg;

  final log = Logger('ForgotPasswordPage');

  @override
  void initState() {
    _emailController = TextEditingController(text: widget._passedEmail);
    super.initState();
  }

  String? _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(email)) {
      return 'The email is invalid';
    }
    return null;
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    setState(() {
      _emailErrorMsg = _validateEmail(email);
    });

    if (_emailErrorMsg != null) {
      setState(() {});
      log.severe('Not proceeding because email is not valid...');
      return Future.value();
    }

    try {
      await AuthService().sendPasswordResetEmail(email);
    } catch (e) {
      _emailErrorMsg = 'Something went wrong. Please try again later';
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Forgot password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Enter your email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'ll send you an email with a link to reset your password. Then you can go back and fill the form with your new password.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // <--- Email field --->
                AuthTextField(
                  key: Key('emailField'),
                  controller: _emailController,
                  hintText: 'Email',
                ),
                const SizedBox(height: 32),

                // <--- Error Message Text --->
                if (_emailErrorMsg != null) ...[
                  Text(
                    _emailErrorMsg!,
                    style: TextStyle(color: Colors.red),
                    softWrap: true,
                    overflow: TextOverflow.clip,
                  ),

                  const SizedBox(height: 24),
                ],

                CooldownAuthButton(
                  onResend: _sendResetEmail,
                  text: 'Resend email',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
