import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../components/territory.dart';

typedef TerritoryCreationCallback = Territory Function(List<LatLng> points,
    List<List<LatLng>>? holePointsList, Map<String, dynamic> properties);
typedef FilterFunction = bool Function(Map<String, dynamic> properties);


/// One should pass these lists when creating adequate layers in flutter_map.
/// For details see example.
///
/// Currently GeoJson parser supports only FeatureCollection and not GeometryCollection.
/// See the GeoJson Format specification at: https://www.rfc-editor.org/rfc/rfc7946
///
/// For creation [Territory] objects the default callback functions
/// are provided which are used in case when no user-defined callback function is provided.
/// To fully customize the [Territory] creation one has to write his own
/// callback functions. As a template the default callback functions can be used.
///
class GeoJsonParser { 
  /// list of [Territory] objects created as result of parsing
  final List<Territory> polygons = [];

   /// user defined callback function that creates a [Territory] object
  TerritoryCreationCallback? territoryCreationCallback;

  /// default [Territory] border color
  Color? defaultTerritoryBorderColor;

  /// default [Territory] fill color
  Color? defaultTerritoryFillColor;

  /// default [Territory] border stroke
  double? defaultTerritoryBorderStroke;

  /// default flag if [Territory] is filled (default is true)
  bool? defaultTerritoryIsFilled;

  /// user defined callback function called during parse for filtering
  FilterFunction? filterFunction;

  /// defined the details of the geojson file parsed
  String geoJsonDetails;

  /// default constructor - all parameters are optional and can be set later with setters
  GeoJsonParser({
    this.territoryCreationCallback,
    this.filterFunction,
    this.defaultTerritoryBorderColor,
    this.defaultTerritoryFillColor,
    this.defaultTerritoryBorderStroke,
    this.defaultTerritoryIsFilled,
    required this.geoJsonDetails,
  });

  /// parse GeJson in [String] format
  void parseGeoJsonAsString(String g) {
    return parseGeoJson(jsonDecode(g) as Map<String, dynamic>);
  }

    /// set default [Territory] fill color
  set setDefaultTerritoryFillColor(Color color) {
    defaultTerritoryFillColor = color;
  }

  /// set default [Territory] border stroke
  set setDefaultTerritoryBorderStroke(double stroke) {
    defaultTerritoryBorderStroke = stroke;
  }

  /// set default [Territory] border color
  set setDefaultTerritoryBorderColorStroke(Color color) {
    defaultTerritoryBorderColor = color;
  }

  /// set default [Territory] setting whether polygon is filled
  set setDefaultTerritoryIsFilled(bool filled) {
    defaultTerritoryIsFilled = filled;
  }

  /// main GeoJson parsing function
  void parseGeoJson(Map<String, dynamic> g) {
    // set default values if they are not specified by constructor
    territoryCreationCallback ??= createDefaultTerritory;
    filterFunction ??= defaultFilterFunction;
    defaultTerritoryBorderColor ??= Colors.black.withOpacity(0.8);
    defaultTerritoryFillColor ??= Colors.black.withOpacity(0.1);
    defaultTerritoryIsFilled ??= true;
    defaultTerritoryBorderStroke ??= 1.0;

    // loop through the GeoJson Map and parse it
    for (Map f in g['features'] as List) {
      String geometryType = f['geometry']['type'].toString();
      // check if this spatial object passes the filter function
      if (!filterFunction!(f['properties'] as Map<String, dynamic>)) {
        continue;
      }
      switch (geometryType) {
        case 'Polygon':
          {
            final List<LatLng> outerRing = [];
            final List<List<LatLng>> holesList = [];
            int pathIndex = 0;
            for (final path in f['geometry']['coordinates'] as List) {
              final List<LatLng> hole = [];
              for (final coords in path as List<dynamic>) {
                if (pathIndex == 0) {
                  // add to polygon's outer ring
                  outerRing
                      .add(LatLng(coords[1] as double, coords[0] as double));
                } else {
                  // add it to current hole
                  hole.add(LatLng(coords[1] as double, coords[0] as double));
                }
              }
              if (pathIndex > 0) {
                // add hole to the polygon's list of holes
                holesList.add(hole);
              }
              pathIndex++;
            }
            polygons.add(territoryCreationCallback!(
                outerRing, holesList, f['properties'] as Map<String, dynamic>));
          }
          break;
        case 'MultiPolygon':
          {
            for (final polygon in f['geometry']['coordinates'] as List) {
              final List<LatLng> outerRing = [];
              final List<List<LatLng>> holesList = [];
              int pathIndex = 0;
              for (final path in polygon as List) {
                List<LatLng> hole = [];
                for (final coords in path as List<dynamic>) {
                  if (pathIndex == 0) {
                    // add to polygon's outer ring
                    outerRing
                        .add(LatLng(coords[1] as double, coords[0] as double));
                  } else {
                    // add it to a hole
                    hole.add(LatLng(coords[1] as double, coords[0] as double));
                  }
                }
                if (pathIndex > 0) {
                  // add to polygon's list of holes
                  holesList.add(hole);
                }
                pathIndex++;
              }
              polygons.add(territoryCreationCallback!(outerRing, holesList,
                  f['properties'] as Map<String, dynamic>));
            }
          }
          break;
      }
    }
    return;
  }

  /// default callback function for creating [Territory]
  Territory createDefaultTerritory(List<LatLng> outerRing,
      List<List<LatLng>>? holesList, Map<String, dynamic> properties) {
    return Territory(
      points: outerRing,
      holePointsList: holesList,
      borderColor: defaultTerritoryBorderColor!,
      color: defaultTerritoryFillColor!,
      //isFilled: defaultTerritoryIsFilled!,
      borderStrokeWidth: defaultTerritoryBorderStroke!,
      iso3: properties['iso3'],
      detailLevel: geoJsonDetails,
      id: properties['id'],
    );
  }

  /// the default filter function returns always true - therefore no filtering
  bool defaultFilterFunction(Map<String, dynamic> properties) {
    return true;
  }
}
