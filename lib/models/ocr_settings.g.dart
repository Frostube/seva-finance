// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OcrSettingsAdapter extends TypeAdapter<OcrSettings> {
  @override
  final int typeId = 7;

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
