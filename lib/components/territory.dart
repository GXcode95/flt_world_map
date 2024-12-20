import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Territory extends Polygon {
  static final Map<String, List<Territory>> _cache = <String, List<Territory>>{
    'simple': [],
    'detailled': [],
  };

  static final List<Territory> _singletons = [];
  
  final String iso3;
  final String detailLevel;
  final int id;

  
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
  // this constructor can be accessed only from within this class
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
    // get the corresponding cache list
    // if it doesn't exist, create it
    // if it exists, check if the color is different
    // if it is, create a new instance with the correct color and replace the old one in the cache.
    // if it is the same, return the existing instance.

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
      _singletons.add(updatedTerritory);
      return updatedTerritory;
    } else {
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
      _singletons.add(newTerritory);
      return newTerritory;
    }
  }

  static List<Territory> getByDetail(String detailLevel) {
    return _cache[detailLevel]!;
  }

  static List<Territory> all(){
    return _singletons;
  }

  static Territory getById(int id) {
    return all().firstWhere((territory) => territory.id == id);
  }

  static List<Territory> getWhereIso3(String iso3) {
    return all().where((territory) => territory.iso3 == iso3).toList();
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
