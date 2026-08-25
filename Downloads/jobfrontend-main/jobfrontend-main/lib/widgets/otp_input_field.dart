import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onCompleted;
  final int length;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() {
        if (_controllers[i].text.length == 1 && i < widget.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }

        String otp = _controllers.map((c) => c.text).join();
        widget.controller.text = otp;

        if (otp.length == widget.length) {
          widget.onCompleted(otp);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGaps = widget.length * 2;
        final double gap = constraints.maxWidth < 360 ? 3.0 : 4.0;
        final double maxBoxW = (constraints.maxWidth - (totalGaps * gap)) / widget.length;
        final double boxW = maxBoxW > 48.0 ? 48.0 : maxBoxW;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final hasText = _controllers[index].text.isNotEmpty;
            return Container(
              width: boxW,
              height: 54,
              margin: EdgeInsets.symmetric(horizontal: gap),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: hasText
                      ? AppColors.primary.withOpacity(0.04)
                      : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasText
                          ? AppColors.primary
                          : const Color(0xFFF1F5F9),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasText
                          ? AppColors.primary
                          : const Color(0xFFF1F5F9),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}