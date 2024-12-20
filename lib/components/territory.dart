import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Territory extends Polygon {
  final String iso3;
  final String detailLevel;
  final int id;

  static final Map<String, List<Territory>> _cache = <String, List<Territory>>{
    'simple': [],
    'detailled': [],
  };

  // Constructors ------------------------

  factory Territory({
    required int id,
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
      id: id,
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
    required this.id,
    required super.points,
    super.color,
    super.borderColor,
    super.holePointsList,
    super.borderStrokeWidth,
    super.label,
    required this.iso3,
    required this.detailLevel,
  }) : super(hitValue: id);


  // Class methods ----------------------
  static Territory findOrCreate({
    required int id,
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
    final existingIndex = cacheList.indexWhere((territory) => territory.id == id);

    if (existingIndex != -1) {
      final existingTerritory = cacheList[existingIndex];
      if (existingTerritory.color == color) {
        return existingTerritory;
      }

      final updatedTerritory = Territory._internal(
        id: id,
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
        id: id,
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

  // Getters ----------------------
  
  String getIso3(){
    return iso3;
  }

  int getId() {
    return id;
  }

  List<LatLng> getPoints() {
    return points;
  }

  List<List<LatLng>>? getHolePointsList() {
    return holePointsList;
  }

  Color? getColor() {
    return color;
  }

  Color getBorderColor() {
    return borderColor;
  }

  double getBorderStrokeWidth() {
    return borderStrokeWidth;
  }

  String getDetailLevel() {
    return detailLevel;
  }

  String? getLabel() {
    return label;
  }


  // Instance methods ------------------

  bool isVisible(LatLngBounds visibleBounds) {
    return points.any((point) => visibleBounds.contains(point));
  }


}
