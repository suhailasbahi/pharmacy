import 'package:flutter/material.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'مسكنات':
      return Colors.red.shade400;
    case 'مضادات حيوية':
      return Colors.blue.shade400;
    case 'فيتامينات':
      return Colors.green.shade400;
    case 'مكملات':
      return Colors.orange.shade400;
    case 'ضغط الدم':
      return Colors.purple.shade400;
    case 'السكري':
      return Colors.indigo.shade400;
    case 'حساسية':
      return Colors.pink.shade400;
    case 'جهاز هضمي':
      return Colors.brown.shade400;
    case 'أطفال':
      return Colors.cyan.shade400;
    default:
      return Colors.teal.shade400;
  }
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'مسكنات':
      return Icons.medication;
    case 'مضادات حيوية':
      return Icons.biotech;
    case 'فيتامينات':
      return Icons.circle;
    case 'مكملات':
      return Icons.fitness_center;
    case 'ضغط الدم':
      return Icons.favorite;
    case 'السكري':
      return Icons.bloodtype;
    case 'حساسية':
      return Icons.air;
    case 'جهاز هضمي':
      return Icons.restaurant;
    case 'أطفال':
      return Icons.child_care;
    default:
      return Icons.medical_information;
  }
}