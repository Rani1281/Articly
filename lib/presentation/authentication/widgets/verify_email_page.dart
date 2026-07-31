import 'dart:async';
import 'package:articly/presentation/authentication/view_models/verify_email_view_model.dart';
import 'package:articly/presentation/authentication/widgets/auth_button.dart';
import 'package:articly/presentation/authentication/widgets/cooldown_widget.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../website_displaying/widgets/new_home_page.dart';

class VerifyEmailScreen extends StatefulWidget {
  VerifyEmailScreen({super.key, VerifyEmailViewModel? viewModel})
    : _viewModel = viewModel ?? VerifyEmailViewModel();

  final VerifyEmailViewModel _viewModel;
  VerifyEmailViewModel get viewModel => _viewModel;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  String? _previousError;

  @override
  void initState() {
    super.initState();
    debugPrint('InitState activated');
    widget.viewModel.addListener(_onViewModelChanged);
    // Send first email verification
    widget.viewModel.sendEmailVerification();

    // Activate timer to check email verification status every 3 seconds

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async => widget.viewModel.checkIfEmailVerified().then((isVerified) {
        if (isVerified) {
          _timer?.cancel();

          // Navigate to the Home page
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => NewHomePage(context)),
              (route) => false,
            );
          }
        }
      }),
    );
  }

  void _onViewModelChanged() {
    final error = widget.viewModel.errorMessage;
    if (error != null && error != _previousError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
    _previousError = error;
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeModel>(
      context,
      listen: false,
    ).isDark(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: kIsWeb
              ? (isDark ? Colors.black : Theme.of(context).colorScheme.surface)
              : Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            title: const Text('Verify email'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: kIsWeb ? EdgeInsets.all(25) : EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: kIsWeb
                        ? (isDark
                              ? Theme.of(context).colorScheme.surface
                              : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Check your email',
                        style: Theme.of(context).textTheme.headlineLarge,
                        // style: TextStyle(
                        //   fontSize: 28,
                        //   fontWeight: FontWeight.bold,
                        //   // color: Colors.black87,
                        // ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ve sent a verification link to your email ${widget.viewModel.getEmail() ?? ''}. Please check your inbox and click the link to verify your account. If you can\'t find it, please check in your spam folder or send again.',

                        // style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      if (widget.viewModel.isEmailVerified)
                        const Text(
                          'Your email is verified!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      const SizedBox(height: 32), // Space before the button

                      CooldownAuthButton(
                        text: 'Resend email',
                        onResend: widget.viewModel.sendEmailVerification,
                        startCounting: true,
                      ),

                      const SizedBox(height: 32),

                      AuthButton(
                        // color: Colors.white,
                        onPressed: widget.viewModel.logOut,
                        child: widget.viewModel.isRunningLogOut
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Log into another account',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
