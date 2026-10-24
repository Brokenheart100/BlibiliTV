// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'probe_check_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProbeCheckDto _$ProbeCheckDtoFromJson(Map<String, dynamic> json) =>
    ProbeCheckDto(
      capability: json['capability'] as String,
      passed: json['passed'] as bool,
      detail: json['detail'] as String,
    );

Map<String, dynamic> _$ProbeCheckDtoToJson(ProbeCheckDto instance) =>
    <String, dynamic>{
      'capability': instance.capability,
      'passed': instance.passed,
      'detail': instance.detail,
    };
