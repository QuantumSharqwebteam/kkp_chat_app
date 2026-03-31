import 'package:flutter/material.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';

class ExtractedProductFormOverlay extends StatefulWidget {
  final Map<String, dynamic> extractedData;
  final Function(Map<String, dynamic>) onSubmit;
  final String? customerName;

  const ExtractedProductFormOverlay({
    super.key,
    required this.extractedData,
    required this.onSubmit,
    this.customerName,
  });

  @override
  State<ExtractedProductFormOverlay> createState() => _ExtractedProductFormOverlayState();
}

class _ExtractedProductFormOverlayState extends State<ExtractedProductFormOverlay> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weaveController = TextEditingController();
  final TextEditingController compositionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with extracted data
    qualityController.text = widget.extractedData['quality']?.toString() ?? '';
    quantityController.text = widget.extractedData['quantity']?.toString() ?? '';
    weaveController.text = widget.extractedData['weave']?.toString() ?? '';
    compositionController.text = widget.extractedData['composition']?.toString() ?? '';
    rateController.text = widget.extractedData['rate']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Validate Extracted Product Data",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Quality",
                        hintText: "e.g., premium, standard, high",
                        border: OutlineInputBorder(),
                      ),
                      controller: qualityController,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        hintText: "e.g., 100 meters, 50 kg",
                        border: OutlineInputBorder(),
                      ),
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Weave",
                        hintText: "e.g., plain, twill, satin",
                        border: OutlineInputBorder(),
                      ),
                      controller: weaveController,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Composition",
                        hintText: "e.g., cotton, polyester, silk",
                        border: OutlineInputBorder(),
                      ),
                      controller: compositionController,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Rate (₹ per unit)",
                        hintText: "e.g., 50",
                        border: OutlineInputBorder(),
                      ),
                      controller: rateController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Confidence: ${(widget.extractedData['confidence'] ?? 0.0) * 100}% - Please review and edit the extracted data as needed.",
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final formData = {
                          "buyerName": widget.customerName ?? "",
                          "quality": qualityController.text.trim(),
                          "quantity": quantityController.text.trim(),
                          "weave": weaveController.text.trim(),
                          "composition": compositionController.text.trim(),
                          "rate": rateController.text.trim().isNotEmpty
                              ? num.tryParse(rateController.text.trim()) ?? 0
                              : 0,
                          "orderId": 'ORD-${DateTime.now().millisecondsSinceEpoch}',
                        };
                        widget.onSubmit(formData);
                      }
                    },
                    text: "Send to Customer",
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
