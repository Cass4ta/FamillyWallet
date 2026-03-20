import 'package:flutter/material.dart';
import '../../core/constants/avatar_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String nombre;
  final int colorIndex;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.nombre,
    required this.colorIndex,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: getAvatarColor(colorIndex),
      child: Text(
        getInitials(nombre),
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
