// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OcrSettingsAdapter extends TypeAdapter<OcrSettings> {
  @override
  final int typeId = 10;

  @override
  OcrSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OcrSettings(
      documentType: fields[0] as String,
      autoCrop: fields[1] as bool,
      ocrMode: fields[2] as OcrMode,
      dateFallback: fields[3] as DateFallback,
      grayscaleThreshold: fields[4] as int,
      brightnessContrast: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OcrSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.documentType)
      ..writeByte(1)
      ..write(obj.autoCrop)
      ..writeByte(2)
      ..write(obj.ocrMode)
      ..writeByte(3)
      ..write(obj.dateFallback)
      ..writeByte(4)
      ..write(obj.grayscaleThreshold)
      ..writeByte(5)
      ..write(obj.brightnessContrast);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OcrModeAdapter extends TypeAdapter<OcrMode> {
  @override
  final int typeId = 8;

  @override
  OcrMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OcrMode.preview;
      case 1:
        return OcrMode.autoSubmit;
      default:
        return OcrMode.preview;
    }
  }

  @override
  void write(BinaryWriter writer, OcrMode obj) {
    switch (obj) {
      case OcrMode.preview:
        writer.writeByte(0);
        break;
      case OcrMode.autoSubmit:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DateFallbackAdapter extends TypeAdapter<DateFallback> {
  @override
  final int typeId = 9;

  @override
  DateFallback read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DateFallback.today;
      case 1:
        return DateFallback.askUser;
      default:
        return DateFallback.today;
    }
  }

  @override
  void write(BinaryWriter writer, DateFallback obj) {
    switch (obj) {
      case DateFallback.today:
        writer.writeByte(0);
        break;
      case DateFallback.askUser:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateFallbackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
