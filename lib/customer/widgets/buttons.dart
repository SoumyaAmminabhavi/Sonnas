import 'package:flutter/material.dart';
import '../theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double width;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 52.0,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: CustomerTheme.primaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double width;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 52.0,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: CustomerTheme.accent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: CustomerTheme.accent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
