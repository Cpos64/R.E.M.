import 'package:flutter/material.dart';

/// List of available dream genres shown in selection chips.
const List<String> dreamGenres = [
  'Normal',
  'Nightmare',
  'Lucid',
  'Recurring',
  'Adventure',
  'Romantic',
  'Funny',
  'Other',
];

/// Color palette for dream genres used throughout the UI.
const Map<String, Color> genreColors = {
  'Normal':    Color(0xFF90A4AE), // blueGrey300
  'Nightmare': Color(0xFFE57373), // red300
  'Lucid':     Color(0xFF9575CD), // deepPurple300
  'Recurring': Color(0xFF4DB6AC), // teal300
  'Adventure': Color(0xFFFFB74D), // orange300
  'Romantic':  Color(0xFFF06292), // pink300
  'Funny':     Color(0xFFFFF176), // yellow300
  'Other':     Color(0xFF64B5F6), // blue300
};
