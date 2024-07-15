import 'package:json_annotation/json_annotation.dart';

part 'mapper_model.g.dart';

@JsonSerializable()
class BytesJsonMapperModel {
  BytesJsonMapperModel({
    this.title = '',
    this.dataLengthType = DataLengthType.fixed,
    this.dataType = DataType.uint,
    int? byteLength,
    this.delimiterBytes,
  }) : byteLength = byteLength ?? dataType.validLenghts.first;

  String title;
  DataType dataType;
  DataLengthType dataLengthType;
  int byteLength;
  List<int>? delimiterBytes;

  factory BytesJsonMapperModel.fromJson(Map<String, dynamic> json) => _$BytesJsonMapperModelFromJson(json);

  Map<String, dynamic> toJson() => _$BytesJsonMapperModelToJson(this);
}

enum DataLengthType { fixed, variable }

enum DataType {
  integer([1, 2, 4, 8]),
  uint([1, 2, 4, 8]),
  float([4, 8]),
  char([1]);

  const DataType(this.validLenghts);

  final List<int> validLenghts;
}
