import 'package:flutter/material.dart';

class UserDot extends StatelessWidget {
  const UserDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.blueAccent.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
