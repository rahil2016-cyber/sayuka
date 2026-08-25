import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({
    super.key,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: height,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: const [
              TextSpan(
                text: 'Job',
                style: TextStyle(color: Color(0xFFE53935)), // Red
              ),
              TextSpan(
                text: 'Allocate',
                style: TextStyle(color: Color(0xFF174A7E)), // Blue
              ),
            ],
          ),
        ),
      ),
    );
  }
}
