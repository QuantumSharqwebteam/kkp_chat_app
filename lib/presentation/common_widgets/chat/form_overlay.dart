import 'package:flutter/material.dart';

class FormOverlay extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController qualityController;
  final TextEditingController quantityController;
  final TextEditingController weaveController;
  final TextEditingController compositionController;
  final VoidCallback onSubmit;

  const FormOverlay({
    super.key,
    required this.formKey,
    required this.qualityController,
    required this.quantityController,
    required this.weaveController,
    required this.compositionController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please fill in the form details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: "Quality"),
              controller: qualityController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quality';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Quantity"),
              controller: quantityController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Weave"),
              controller: weaveController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter weave';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Composition"),
              controller: compositionController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter composition';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSubmit,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
