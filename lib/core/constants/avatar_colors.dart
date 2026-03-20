import 'package:flutter/material.dart';

const List<Color> avatarColors = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
];

Color getAvatarColor(int index) {
  return avatarColors[index % avatarColors.length];
}

String getInitials(String name) {
  if (name.isEmpty) return '';
  return name[0].toUpperCase();
}
