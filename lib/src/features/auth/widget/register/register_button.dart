import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../localization/locator.dart';
import '../../../sign_up/sign_up_controller.dart';

class RegisterButton extends StatefulWidget {
  const RegisterButton({super.key});

  @override
  State<RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<RegisterButton> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = locator.get<SignUpController>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.only(
          top: 30, left: 16, right: 16),
      child: TextButton(
        onPressed: () {
          final valid = _formKey.currentState != null &&
              _formKey.currentState!.validate();
          if (valid) {
            _controller.signUp(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            );
          } else {
            log("erro ao logar");
          }
        },
        style: ButtonStyle(
            elevation: WidgetStateProperty.all(6),
            backgroundColor:
            WidgetStateProperty.all<
                Color>(
                Colors.deepOrange),
            shape: WidgetStateProperty.all<
                RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        32.0),
                    side: const BorderSide(
                        color: Colors.red)))),
        child: Text(
            "REGISTRAR"
                .toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            )),
      ),
    );
  }
}
