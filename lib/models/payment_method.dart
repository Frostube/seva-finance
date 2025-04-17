import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String? icon;
  final String? lastFourDigits;
  final Color color;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    this.icon,
    this.lastFourDigits,
    Color? color,
    DateTime? createdAt,
  }) : color = color ?? const Color(0xFF1B4332),
       createdAt = createdAt ?? DateTime.now();

  PaymentMethod copyWith({
    String? name,
    String? icon,
    String? lastFourDigits,
    Color? color,
  }) {
    return PaymentMethod(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'lastFourDigits': lastFourDigits,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      lastFourDigits: json['lastFourDigits'] as String?,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
} 