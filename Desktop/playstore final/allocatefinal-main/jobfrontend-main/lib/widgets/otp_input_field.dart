import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';

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

class _OtpInputFieldState extends State<OtpInputField> with CodeAutoFill {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _distributing = false;
  String? _lastCompleted;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      node.onKeyEvent = (FocusNode n, KeyEvent event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.backspace) {
          return KeyEventResult.ignored;
        }
        if (_controllers[i].text.isEmpty && i > 0) {
          _controllers[i - 1].clear();
          _focusNodes[i - 1].requestFocus();
          _syncParent();
          setState(() {});
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
      return node;
    });
    _startSmsListen();
  }

  Future<void> _startSmsListen() async {
    try {
      listenForCode();
    } catch (_) {
      // Best-effort on Android; paste + system autofill still work.
    }
  }

  @override
  void codeUpdated() {
    final smsCode = code;
    if (smsCode == null || smsCode.isEmpty) return;
    _fillFromRaw(smsCode);
  }

  void _fillFromRaw(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    _distributing = true;
    try {
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text =
            i < digits.length ? digits[i] : '';
      }
      final filled = _controllers.map((c) => c.text).join();
      widget.controller.text = filled;

      final focusAt = (digits.length >= widget.length)
          ? widget.length - 1
          : digits.length.clamp(0, widget.length - 1);
      _focusNodes[focusAt].requestFocus();

      if (filled.length == widget.length && filled != _lastCompleted) {
        _lastCompleted = filled;
        widget.onCompleted(filled);
      }
    } finally {
      _distributing = false;
      if (mounted) setState(() {});
    }
  }

  void _syncParent() {
    final otp = _controllers.map((c) => c.text).join();
    widget.controller.text = otp;
    if (otp.length == widget.length && otp != _lastCompleted) {
      _lastCompleted = otp;
      widget.onCompleted(otp);
    } else if (otp.length < widget.length) {
      _lastCompleted = null;
    }
  }

  void _onBoxChanged(int index, String value) {
    if (_distributing) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Paste / SMS autofill dumped the whole code into one box
    if (digits.length > 1) {
      _fillFromRaw(digits);
      return;
    }

    if (digits.length == 1) {
      if (_controllers[index].text != digits) {
        _controllers[index].text = digits;
        _controllers[index].selection =
            const TextSelection.collapsed(offset: 1);
      }
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    _syncParent();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGaps = widget.length * 2;
          final double gap = constraints.maxWidth < 360 ? 3.0 : 4.0;
          final double maxBoxW =
              (constraints.maxWidth - (totalGaps * gap)) / widget.length;
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
                  textInputAction: index == widget.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  autofillHints:
                      index == 0 ? const [AutofillHints.oneTimeCode] : null,
                  enableSuggestions: true,
                  inputFormatters: [
                    // Allow full paste; digits are split across boxes in onChanged.
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(widget.length),
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
                  onChanged: (value) => _onBoxChanged(index, value),
                  onTap: () {
                    _controllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controllers[index].text.length,
                    );
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    cancel();
    try {
      SmsAutoFill().unregisterListener();
    } catch (_) {}
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
