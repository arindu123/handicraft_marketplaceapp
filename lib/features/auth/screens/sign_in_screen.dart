import 'package:flutter/material.dart';

import '../widgets/auth_form.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthForm(isSignUp: false);
}
