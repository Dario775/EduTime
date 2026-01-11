import 'package:flutter/material.dart';

class StudyCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const StudyCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Predefined categories
final List<StudyCategory> studyCategories = [
  const StudyCategory(
    id: 'math',
    name: 'Matemáticas',
    icon: Icons.calculate,
    color: Color(0xFF2563EB), // Blue
  ),
  const StudyCategory(
    id: 'science',
    name: 'Ciencias',
    icon: Icons.science,
    color: Color(0xFF10B981), // Green
  ),
  const StudyCategory(
    id: 'language',
    name: 'Lengua',
    icon: Icons.menu_book,
    color: Color(0xFFEF4444), // Red
  ),
  const StudyCategory(
    id: 'history',
    name: 'Historia',
    icon: Icons.history_edu,
    color: Color(0xFF8B5CF6), // Purple
  ),
  const StudyCategory(
    id: 'art',
    name: 'Arte',
    icon: Icons.palette,
    color: Color(0xFFF59E0B), // Amber
  ),
  const StudyCategory(
    id: 'programming',
    name: 'Programación',
    icon: Icons.code,
    color: Color(0xFF06B6D4), // Cyan
  ),
  const StudyCategory(
    id: 'languages',
    name: 'Idiomas',
    icon: Icons.translate,
    color: Color(0xFFEC4899), // Pink
  ),
  const StudyCategory(
    id: 'other',
    name: 'Otro',
    icon: Icons.more_horiz,
    color: Color(0xFF6B7280), // Gray
  ),
];

StudyCategory? getCategoryById(String id) {
  try {
    return studyCategories.firstWhere((cat) => cat.id == id);
  } catch (e) {
    return null;
  }
}
