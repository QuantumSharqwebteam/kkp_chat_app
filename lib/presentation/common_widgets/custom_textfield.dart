import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.width = double.infinity,
    this.height = 45,
    this.isPassword = false,
    this.keyboardType,
    this.errorText,
    this.borderRadius = 10,
    this.hintText,
    this.helperText,
    this.helperStyle,
    this.condition,
    this.textStyle,
    this.hintStyle,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.backgroundColor,
    this.minLines = 1,
    this.maxLines = 1,
    this.inputFormatters, // ✅ Added inputFormatters
    this.onChanged, // Add onChanged callback
  });

  final double width;
  final double height;
  final double borderRadius;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? hintText;
  final String? helperText;
  final TextStyle? helperStyle;
  final bool Function(String)? condition;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final Color? backgroundColor;
  final List<TextInputFormatter>? inputFormatters; // ✅ New parameter
  final ValueChanged<String>? onChanged; // Define onChanged callback

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;
  bool _showCheckmark = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCheckmark);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCheckmark);
    super.dispose();
  }

  void _updateCheckmark() {
    if (widget.condition != null) {
      setState(() {
        _showCheckmark = widget.condition!(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.errorText != null ? widget.height + 20 : widget.height,
          child: TextFormField(
            obscuringCharacter: '*',
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword ? _isObscured : false,
            style: widget.textStyle ?? const TextStyle(fontSize: 14.0),
            readOnly: widget.readOnly,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            inputFormatters: widget.inputFormatters, // ✅ Apply inputFormatters
            onChanged: widget.onChanged, // Pass onChanged callback
            decoration: InputDecoration(
              filled: true,
              errorText: widget.errorText,
              fillColor: widget.backgroundColor ?? Colors.white,
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ??
                  const TextStyle(fontSize: 14.0, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: widget.errorText != null
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: widget.errorText != null
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: widget.errorText != null ? Colors.red : Colors.grey,
                  width: 2,
                ),
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isPassword)
                        IconButton(
                          icon: Icon(_isObscured
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() => _isObscured = !_isObscured);
                          },
                        ),
                      if (_showCheckmark)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(Icons.check_circle, color: Colors.black),
                        ),
                    ],
                  ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
        if (widget.helperText != null) // Helper text below the text field
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              widget.helperText!,
              style: widget.helperStyle ??
                  const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
      ],
    );
  }
}
