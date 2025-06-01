import 'package:hive/hive.dart';

part 'ocr_settings.g.dart';

enum OcrMode { preview, autoSubmit }
enum DateFallback { today, askUser }

@HiveType(typeId: 7) // Ensure this typeId is unique
class OcrSettings extends HiveObject {
  @HiveField(0)
  String documentType;

  @HiveField(1)
  bool autoCrop;

  @HiveField(2)
  OcrMode ocrMode;

  @HiveField(3)
  DateFallback dateFallback;

  @HiveField(4)
  int grayscaleThreshold; // 0-100

  @HiveField(5)
  int brightnessContrast; // -50 to +50 (could be split later if needed)

  OcrSettings({
    this.documentType = 'Other',
    this.autoCrop = true,
    this.ocrMode = OcrMode.preview,
    this.dateFallback = DateFallback.today,
    this.grayscaleThreshold = 50, // Default midpoint
    this.brightnessContrast = 0,   // Default neutral
  });

  // Method to reset to default values
  void resetToDefaults() {
    documentType = 'Other';
    autoCrop = true;
    ocrMode = OcrMode.preview;
    dateFallback = DateFallback.today;
    grayscaleThreshold = 50;
    brightnessContrast = 0;
  }

  OcrSettings copyWith({
    String? documentType,
    bool? autoCrop,
    OcrMode? ocrMode,
    DateFallback? dateFallback,
    int? grayscaleThreshold,
    int? brightnessContrast,
  }) {
    return OcrSettings(
      documentType: documentType ?? this.documentType,
      autoCrop: autoCrop ?? this.autoCrop,
      ocrMode: ocrMode ?? this.ocrMode,
      dateFallback: dateFallback ?? this.dateFallback,
      grayscaleThreshold: grayscaleThreshold ?? this.grayscaleThreshold,
      brightnessContrast: brightnessContrast ?? this.brightnessContrast,
    );
  }
} 