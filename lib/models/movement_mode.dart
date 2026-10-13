import 'package:flutter/material.dart';

enum MovementMode {
  seated(
    label: 'SEATED',
    description: 'Move from your seat',
    detail: 'A relaxed adventure with comfortable seated movement.',
    icon: Icons.event_seat_rounded,
    accent: Color(0xFF65D8C1),
  ),
  gentle(
    label: 'GENTLE',
    description: 'Take it at your pace',
    detail: 'Easy-going moves for a feel-good family adventure.',
    icon: Icons.self_improvement_rounded,
    accent: Color(0xFFC2F36B),
  ),
  active(
    label: 'ACTIVE',
    description: 'Bring your energy',
    detail: 'A lively adventure for when you are ready to move more.',
    icon: Icons.bolt_rounded,
    accent: Color(0xFFFFD477),
  );

  const MovementMode({
    required this.label,
    required this.description,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String description;
  final String detail;
  final IconData icon;
  final Color accent;
}
