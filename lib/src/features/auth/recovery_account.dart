import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../../ui/components/atoms/custom_text_form_field.dart';

class RecoveryAccount extends StatelessWidget {
  RecoveryAccount({super.key});

  final form = FormGroup({
    'email': FormControl<String>(
        validators: [Validators.required, Validators.email]),
    'password': FormControl<String>(
        validators: [Validators.required, Validators.minLength(8)]),
    'emailConfirmation': FormControl<String>(),
  }, validators: [
    Validators.mustMatch('email', 'emailConfirmation'),
  ]);

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 16,
                ),
                child: Text('Trocar senha',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 120, left: 16, right: 16),
              child: Text(
                  'Identifique-se para receber um e-mail com as instruções e o link para criar uma nova senha.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: thmode.darkMode ? AppColors.lightBG : Colors.grey.shade300,
                    fontSize: 18
                  )),
            ),
            ReactiveForm(
                formGroup: form,
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 16,
                    left: 16,
                    right: 16
                  ),
                  child: const CustomTextFormField(
                    labelText: 'email',
                  ),
                ),),
            Container(
              height: 40,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 30),
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: TextButton(
                onPressed: () {},
                style: ButtonStyle(
                    elevation: WidgetStateProperty.all(6),
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.deepOrange),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: const BorderSide(color: Colors.red)))),
                child: Text("Recuperar senha".toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}
