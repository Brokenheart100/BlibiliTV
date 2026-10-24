import 'package:json_annotation/json_annotation.dart';

import '../domain/probe_models.dart';

part 'probe_check_dto.g.dart';

@JsonSerializable()
class ProbeCheckDto {
  const ProbeCheckDto({
    required this.capability,
    required this.passed,
    required this.detail,
  });
  factory ProbeCheckDto.fromJson(Map<String, Object?> json) =>
      _$ProbeCheckDtoFromJson(json);
  factory ProbeCheckDto.fromDomain(ProbeCheck check) => ProbeCheckDto(
    capability: check.capability,
    passed: check.passed,
    detail: check.detail,
  );
  final String capability;
  final bool passed;
  final String detail;
  Map<String, Object?> toJson() => _$ProbeCheckDtoToJson(this);
}
