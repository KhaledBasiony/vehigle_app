// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapper_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BytesJsonMapperModel _$BytesJsonMapperModelFromJson(
        Map<String, dynamic> json) =>
    BytesJsonMapperModel(
      title: json['title'] as String? ?? '',
      dataLengthType: $enumDecodeNullable(
              _$DataLengthTypeEnumMap, json['dataLengthType']) ??
          DataLengthType.fixed,
      dataType: $enumDecodeNullable(_$DataTypeEnumMap, json['dataType']) ??
          DataType.uint,
      byteLength: (json['byteLength'] as num?)?.toInt(),
      delimiterBytes: (json['delimiterBytes'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$BytesJsonMapperModelToJson(
        BytesJsonMapperModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'dataType': _$DataTypeEnumMap[instance.dataType]!,
      'dataLengthType': _$DataLengthTypeEnumMap[instance.dataLengthType]!,
      'byteLength': instance.byteLength,
      'delimiterBytes': instance.delimiterBytes,
    };

const _$DataLengthTypeEnumMap = {
  DataLengthType.fixed: 'fixed',
  DataLengthType.variable: 'variable',
};

const _$DataTypeEnumMap = {
  DataType.integer: 'integer',
  DataType.uint: 'uint',
  DataType.float: 'float',
  DataType.char: 'char',
};
