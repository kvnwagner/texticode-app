import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final double size;
  final Color bg;
  final Color text;

  const AvatarWidget({
    super.key,
    required this.initials,
    this.size = 40,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.33,
        ),
      ),
    );
  }
}
