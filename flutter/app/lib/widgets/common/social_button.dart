
// 소셜 로그인 버튼 컴포넌트
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String assetPath;
  final String text;
  final VoidCallback onPressed;

  const SocialButton({
    required this.assetPath,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Image.asset(assetPath, width: 24, height: 24),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF3B2D2C),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size(280, 56),
        side: BorderSide(color: Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}