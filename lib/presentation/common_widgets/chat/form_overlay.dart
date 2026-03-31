import 'package:flutter/material.dart';

class FormOverlay extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const FormOverlay({super.key, required this.onSubmit});

  @override
  State<FormOverlay> createState() => _FormOverlayState();
}

class _FormOverlayState extends State<FormOverlay> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weaveController = TextEditingController();
  final TextEditingController compositionController = TextEditingController();
  final TextEditingController buyernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please fill in the form details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: "Buyer Name"),
              controller: buyernameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter buyer name';
                }
                return null;
              },
            ),
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final formData = {
                    "buyerName": buyernameController.text,
                    "quality": qualityController.text,
                    "quantity": quantityController.text,
                    "weave": weaveController.text,
                    "composition": compositionController.text,
                    "rate": 0,
                  };
                  widget.onSubmit(formData);
                  Navigator.pop(context);
                }
              },
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
