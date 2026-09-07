import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nammaooru_mobile_app/core/utils/form_validators.dart';

void main() {
  testWidgets('post mobile field enforces the shared validation rules',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: FormValidators.mobileExample,
              ),
              validator: (value) => FormValidators.isValidIndianMobile(value)
                  ? null
                  : 'Enter a valid mobile number',
            ),
          ),
        ),
      ),
    );

    expect(find.text(FormValidators.mobileExample), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '1234567890');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a valid mobile number'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '9876543210');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
