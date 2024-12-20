import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Territory extends Polygon {
  final String iso3;
  final String detailLevel;

  static final Map<String, List<Territory>> _cache = <String, List<Territory>>{
    'simple': [],
    'detailled': [],
  };

  factory Territory({
    required List<LatLng> points,
    required Color color,
    required Color borderColor,
    required double borderStrokeWidth,
    required String iso3,
    required String detailLevel,
    String? label,
    List<List<LatLng>>? holePointsList,
  }) {
    // get the corresponding cache list
    // if it doesn't exist, create it
    // if it exists, check if the color is different
    // if it is, create a new instance with the correct color and replace the old one in the cache.
    // if it is the same, return the existing instance.
    return Territory.findOrCreate(
      points: points,
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      iso3: iso3,
      detailLevel: detailLevel,
      label: label,
      holePointsList: holePointsList,
    );
  }

  // _ are private to the class scope
  // internal is a common name for a private constructor
  // this coinstructor can be accessed only from within this class
  Territory._internal({
    required super.points,
    super.color,
    super.borderColor,
    super.holePointsList,
    super.borderStrokeWidth,
    super.label,
    required this.iso3,
    required this.detailLevel,
  }) : super(hitValue: iso3);

  static Territory findOrCreate({
    required List<LatLng> points,
    required Color color,
    required Color borderColor,
    required double borderStrokeWidth,
    required String iso3,
    required String detailLevel,
    String? label,
    List<List<LatLng>>? holePointsList,
  }) {
  
    final List<Territory> cacheList = _cache[detailLevel]!;
    final existingIndex = cacheList.indexWhere((territory) => territory.iso3 == iso3);

    if (existingIndex != -1) {
      final existingTerritory = cacheList[existingIndex];
      if (existingTerritory.color == color) {
        return existingTerritory;
      }

      final updatedTerritory = Territory._internal(
        points: points,
        color: color,
        borderColor: borderColor,
        holePointsList: holePointsList,
        borderStrokeWidth: borderStrokeWidth,
        label: label,
        iso3: iso3,
        detailLevel: detailLevel,
      );
      cacheList[existingIndex] = updatedTerritory;
      return updatedTerritory;
    } else {
      // Ajouter un nouveau Territory si inexistant dans le cache.
      final newTerritory = Territory._internal(
        points: points,
        color: color,
        borderColor: borderColor,
        holePointsList: holePointsList,
        borderStrokeWidth: borderStrokeWidth,
        label: label,
        iso3: iso3,
        detailLevel: detailLevel,
      );
      cacheList.add(newTerritory);
      return newTerritory;
    }
  }

  static List<Territory> getByDetail(String detailLevel) {
    return _cache[detailLevel]!;
  }

  bool isVisible(LatLngBounds visibleBounds) {
    return points.any((point) => visibleBounds.contains(point));
  }
}
