import 'package:flutter/material.dart';

class SentProductFormBubble extends StatelessWidget {
  final Map<String, dynamic> formData;
  final bool isMe;
  final String timestamp;
  final int? serialNumber;
  final void Function(String)? onStatusUpdate;
  final void Function(num)? onRateUpdate;

  const SentProductFormBubble({
    super.key,
    required this.formData,
    required this.isMe,
    required this.timestamp,
    this.serialNumber,
    this.onStatusUpdate,
    this.onRateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = formData['orderId'] ?? formData['_id'] ?? '';
    final displayOrderId = orderId.isNotEmpty ? orderId : 'N/A';
    final buyerName = formData['buyerName'] ?? formData['customerName'] ?? '';
    final quality = formData['quality']?.toString() ?? '';
    final weave = formData['weave']?.toString() ?? '';
    final quantity = formData['quantity']?.toString() ?? '';
    final composition = formData['composition']?.toString() ?? '';
    final rate = formData['rate']?.toString() ?? '';
    final highlight = formData['_highlightUpdated'] == true;

    final bubbleColor =
        isMe ? (highlight ? Colors.green.shade600 : Colors.blue[700]) : Colors.grey.shade200;

    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: highlight ? Border.all(color: Colors.yellow.shade300, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serialNumber != null ? 'Order #$serialNumber' : 'Order ID',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 4),
            Text('Order ID: $displayOrderId',
                style: TextStyle(
                    fontSize: 12, color: textColor.withOpacity(0.9), fontWeight: FontWeight.w600)),
            if (highlight) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Order updated',
                    style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 6),
            _buildRow('Buyer', buyerName, textColor),
            _buildRow('Quality', quality, textColor),
            _buildRow('Weave', weave, textColor),
            _buildRow('Quantity', quantity, textColor),
            _buildRow('Composition', composition, textColor),
            _buildRow('Rate', rate.isNotEmpty ? '₹$rate' : '-', textColor),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  timestamp,
                  style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
