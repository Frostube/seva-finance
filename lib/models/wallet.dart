import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

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
  DateTime createdAt;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  double? budget;

  @HiveField(7)
  String? type;

  @HiveField(8)
  int? iconCodePoint;

  static const IconData defaultIcon = CupertinoIcons.money_dollar_circle_fill;

  // Predefined map of known icons for tree shaking
  // Manually providing code points as they cannot be accessed in const initializers directly.
  static const Map<int, IconData> _knownIcons = {
    0xf3cd: CupertinoIcons.money_dollar_circle_fill, // defaultIcon
    0xf2d2: CupertinoIcons.cart_fill,
    0xf2dd: CupertinoIcons.car_fill,
    0xf447: CupertinoIcons.house_fill,
    0xf427: CupertinoIcons.gift_fill,
    0xf43e: CupertinoIcons.heart_fill,
    0xf4dd: CupertinoIcons.person_2_fill,
    0xf2a7: CupertinoIcons.bag_fill,
    0xf297: CupertinoIcons.airplane,
    0xf424: CupertinoIcons.game_controller_solid,
    0xf525: CupertinoIcons.star_fill,
    0xf539: CupertinoIcons.tag_fill,
  };

  static Wallet get empty => Wallet(
    id: '',
    name: 'Unknown Wallet',
    balance: 0.0,
    isPrimary: false,
    createdAt: DateTime.now(),
    colorValue: const Color(0xFF1E1E1E).value, 
    icon: defaultIcon,
  );

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
  }) : iconCodePoint = icon?.codePoint ?? defaultIcon.codePoint;

  IconData get icon {
    return _knownIcons[iconCodePoint] ?? defaultIcon;
  }

  set icon(IconData value) {
    iconCodePoint = value.codePoint;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'isPrimary': isPrimary,
      'createdAt': Timestamp.fromDate(createdAt),
      'colorValue': colorValue,
      'budget': budget,
      'type': type,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    dynamic createdAtData = json['createdAt'];
    DateTime createdAtDate;

    if (createdAtData is Timestamp) {
      createdAtDate = createdAtData.toDate();
    } else if (createdAtData is String) {
      try {
        createdAtDate = DateTime.parse(createdAtData);
        print('Wallet.fromJson: Parsed createdAt string "$createdAtData" to DateTime.');
      } catch (e) {
        print('Wallet.fromJson: Error parsing createdAt string "$createdAtData": $e. Falling back to DateTime.now().');
        createdAtDate = DateTime.now(); // Fallback
      }
    } else if (createdAtData == null) {
      print('Wallet.fromJson: createdAt field is null. Falling back to DateTime.now().');
      createdAtDate = DateTime.now(); // Fallback for null
    } else {
      print('Wallet.fromJson: Unexpected type for createdAt: ${createdAtData.runtimeType}. Value: $createdAtData. Falling back to DateTime.now().');
      createdAtDate = DateTime.now(); // Fallback for other unexpected types
    }

    int currentIconCodePoint = json['iconCodePoint'] as int? ?? defaultIcon.codePoint;
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      isPrimary: json['isPrimary'] as bool,
      createdAt: createdAtDate, // Use the processed date
      colorValue: json['colorValue'] as int,
      budget: (json['budget'] as num?)?.toDouble(),
      type: json['type'] as String?,
      icon: _knownIcons[currentIconCodePoint] ?? defaultIcon,
    );
  }

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    bool? isPrimary,
    DateTime? createdAt,
    int? colorValue,
    double? budget,
    String? type,
    IconData? icon,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      colorValue: colorValue ?? this.colorValue,
      budget: budget ?? this.budget,
      type: type ?? this.type,
      icon: icon ?? this.icon,
    );
  }
} 