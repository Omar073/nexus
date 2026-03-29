import 'dart:convert';
import 'package:flutter/material.dart';

/// Hive model for a named saved color palette.
class ColorPreset {
  final String id;
  final String name;
  final Color lightPrimary;
  final Color lightSecondary;
  final Color darkPrimary;
  final Color darkSecondary;
  final DateTime createdAt;

  const ColorPreset({
    required this.id,
    required this.name,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.createdAt,
  });

  /// Create a preset from current colors
  factory ColorPreset.fromCurrentColors({
    required String name,
    required Color lightPrimary,
    required Color lightSecondary,
    required Color darkPrimary,
    required Color darkSecondary,
  }) {
    return ColorPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lightPrimary: lightPrimary,
      lightSecondary: lightSecondary,
      darkPrimary: darkPrimary,
      darkSecondary: darkSecondary,
      createdAt: DateTime.now(),
    );
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lightPrimary': lightPrimary.toARGB32(),
      'lightSecondary': lightSecondary.toARGB32(),
      'darkPrimary': darkPrimary.toARGB32(),
      'darkSecondary': darkSecondary.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON map
  factory ColorPreset.fromJson(Map<String, dynamic> json) {
    return ColorPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      lightPrimary: Color(json['lightPrimary'] as int),
      lightSecondary: Color(json['lightSecondary'] as int),
      darkPrimary: Color(json['darkPrimary'] as int),
      darkSecondary: Color(json['darkSecondary'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Encode list of presets to JSON string
  static String encodeList(List<ColorPreset> presets) {
    return jsonEncode(presets.map((p) => p.toJson()).toList());
  }

  /// Decode list of presets from JSON string
  static List<ColorPreset> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ColorPreset.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
