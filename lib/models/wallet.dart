import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 1)
class Wallet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double balance;

  @HiveField(3)
  bool isPrimary;

  @HiveField(4)
  String createdAt;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  double? budget;

  @HiveField(7)
  String? type;

  @HiveField(8)
  int? iconData;

  static const IconData defaultIcon = CupertinoIcons.money_dollar_circle_fill;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.isPrimary,
    required this.createdAt,
    required this.colorValue,
    this.budget,
    this.type,
    IconData? icon,
  }) : iconData = icon?.codePoint;

  IconData get icon => IconData(
    iconData ?? defaultIcon.codePoint,
    fontFamily: defaultIcon.fontFamily,
    fontPackage: defaultIcon.fontPackage,
  );

  set icon(IconData value) {
    iconData = value.codePoint;
  }

  // Convert to JSON (for database operations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'isPrimary': isPrimary,
      'createdAt': createdAt,
      'colorValue': colorValue,
      'budget': budget,
    };
  }

  // Create a copy of this Wallet with optional field updates
  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    bool? isPrimary,
    String? createdAt,
    int? colorValue,
    double? budget,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      colorValue: colorValue ?? this.colorValue,
      budget: budget ?? this.budget,
    );
  }
} 