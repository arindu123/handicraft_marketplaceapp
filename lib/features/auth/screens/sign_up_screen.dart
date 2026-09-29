import 'package:flutter/material.dart';

import '../widgets/auth_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthForm(isSignUp: true);
}
