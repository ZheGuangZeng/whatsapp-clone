import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom OTP input field widget
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.length = 6,
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final int length;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    
    // Sync with main controller
    widget.controller.addListener(_syncMainController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncMainController);
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncMainController() {
    final mainText = widget.controller.text;
    for (int i = 0; i < widget.length; i++) {
      if (i < mainText.length) {
        _controllers[i].text = mainText[i];
      } else {
        _controllers[i].clear();
      }
    }
  }

  void _updateMainController() {
    final combinedText = _controllers.map((c) => c.text).join();
    widget.controller.text = combinedText;
    widget.onChanged?.call(combinedText);
  }

  void _onTextChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, unfocus
        FocusScope.of(context).unfocus();
      }
    } else {
      // Move to previous field when deleting
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    _updateMainController();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNodes[index].hasFocus
                  ? Colors.green
                  : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _onTextChanged(index, value),
            onTap: () {
              // Clear current field on tap
              _controllers[index].clear();
              _updateMainController();
            },
          ),
        );
      }),
    );
  }
}