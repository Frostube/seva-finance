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
    iconData ?? CupertinoIcons.money_dollar_circle_fill.codePoint,
    fontFamily: 'CupertinoIcons',
    fontPackage: 'cupertino_icons',
  );

  set icon(IconData value) {
    iconData = value.codePoint;
  }
} 