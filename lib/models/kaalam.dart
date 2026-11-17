import 'package:json_annotation/json_annotation.dart';

part 'kaalam.g.dart';

/// A speed (kaalam) expressed as swaras per beat in Adi Tala.
@JsonSerializable()
class KaalamSpeed {
  const KaalamSpeed({
    required this.kaalam,
    required this.name,
    required this.sanskritName,
    required this.swarasPerBeat,
  });

  factory KaalamSpeed.fromJson(Map<String, dynamic> json) =>
      _$KaalamSpeedFromJson(json);

  final int kaalam;
  final String name;
  final String sanskritName;
  final int swarasPerBeat;

  Map<String, dynamic> toJson() => _$KaalamSpeedToJson(this);
}

const List<KaalamSpeed> kKaalamOptions = [
  KaalamSpeed(
    kaalam: 1,
    name: 'Tempo 1 (1st Kaalam)',
    sanskritName: 'Vilamba',
    swarasPerBeat: 1,
  ),
  KaalamSpeed(
    kaalam: 2,
    name: 'Tempo 2 (2nd Kaalam)',
    sanskritName: 'Madhya',
    swarasPerBeat: 2,
  ),
  KaalamSpeed(
    kaalam: 3,
    name: 'Tempo 3 (3rd Kaalam)',
    sanskritName: 'Druta',
    swarasPerBeat: 4,
  ),
  KaalamSpeed(
    kaalam: 4,
    name: 'Tempo 4 (4th Kaalam)',
    sanskritName: 'Ati-Druta',
    swarasPerBeat: 8,
  ),
];
