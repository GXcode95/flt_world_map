// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {  
  final LayerHitNotifier hitNotifier = ValueNotifier(null); 
  bool loadingData = false;
  double mapZoom = 0.0;
  String zoomLevel = 'detailled';
  /// GeoJsonParser is a class that allow to parse a geoJson file and return a list of polygons
    /// it can track all information about the polygons rendering (color, border color, border width, label, points)
    /// since they take some time to parse the geonjson it guess it's better to have one for each geojson file
    /// representing the different level of details
    /// and swap them based on zoom level
  Map<String, GeoJsonParser> geoParsers = {
    'simple': GeoJsonParser(defaultMarkerColor: Colors.red,
                            defaultPolygonBorderColor: const Color.fromARGB(255, 73, 54, 244),
                            defaultPolygonFillColor: const Color.fromARGB(255, 54, 206, 244).withOpacity(0.2),
                            defaultCircleMarkerColor: const Color.fromARGB(255, 47, 76, 204).withOpacity(0.25)),
    'detailled': GeoJsonParser(defaultMarkerColor: Colors.red,
                               defaultPolygonBorderColor: const Color.fromARGB(255, 73, 54, 244),
                               defaultPolygonFillColor: const Color.fromARGB(255, 55, 233, 0).withOpacity(0.2),
                               defaultCircleMarkerColor: const Color.fromARGB(255, 47, 76, 204).withOpacity(0.25))
  };
  final Map<String, List<Polygon>?> _cachedPolygonsObject = {
    'simple': null,
    'detailled': null,
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
// -------------------------------------------------------
  /// Map options define the map position and behavior
  /// allow handle the camera limitation, and event directly on the map, and probably other things

  /// more about global event listening: https://docs.fleaflet.dev/usage/programmatic-interaction/listen-to-events
//-------------------------------------------------------
            options: MapOptions(
              initialCenter: const LatLng(51.5, -0.09),
              initialZoom: 5,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-90, -180),
                  const LatLng(90, 180),
                ),
              ),
              onPositionChanged: (camera, hasGesture) => updateCameraZoom(camera),
              onTap: (_, __) => hitNotifier.value = null, // reset hitNotifier when the map is tapped without any event triggererd
            ),
            children: [
              Builder(
                builder: (context) {
                  final visibleBounds = MapCamera.of(context).visibleBounds;
// ---------------------------------------------------------
  /// here we use MouseRegion() to detect the mouse hoverevents
  /// the event detected is defered to childs so if a child trigger the same event, it's the child one which has the priority
  /// The GestureDetector() is used to detect the click event
  /// (can also detect more, but here onTap listen only for tapEvent)
  /// Wrap a GestureDetector() with a MouseRegion() to detect the mouse hover events and the click event together is a common pattern
  /// it's more or less equivalent to onHover + onClick in react
  /// or to set eventListeners for mouseover, mouseout, mousemove and click in vanilla JS
// ---------------------------------------------------------
                  return MouseRegion(
                    hitTestBehavior: HitTestBehavior.deferToChild,
                    cursor: SystemMouseCursors.click, // change the appearance of the cursor
                    child: GestureDetector(
                      onTap: () {
                        final LayerHitResult? hitResult = hitNotifier.value;
                        if (hitResult == null) return;
                        
                        /// hitValues: the hitValues of all elements that were hit,
                        /// ordered by their corresponding element,
                        /// first-to-last, visually top-to-bottom
                        print('${hitResult.hitValues}');
                      },
// ---------------------------------------------------------
  /// Polygons are widget that allow to create vector shapes and can be rendered.
  /// The polygons doesn't handle interactions.
  /// It's about having a separation between the rendering and the interactions (and prob also perf).

  /// To handle intreactions we need to use interactions widget like the hitNotifier
  /// But to avoid using a lot of hitNotifier, we wrap the polygons in a PolygonLayer.
  /// The PolygonLayer represent a group a polygon and can have a hit notifier,
  /// so the polygonLayer (and polygons) handle the rendering and the hitNotifier handle the interactions.

  /// Each polygon have a hitValue, which is a unique identifier for the polygon.
  /// when a polygon is hit, the hitValue is passed to the hitNotifier.
  /// It mean that the PolygonLayer, which is linked to the hitNotifier, now have the information of which polygon is hit.
  /// So we can retrieve this value in the onTap event of the GestureDetector. -> (JUST ABOVE THIS COMMENT)
  /// (which is triggered everytime a tap event happens, even if it doesn't hit a hitNotifier)

  /// More about Layers event handling: https://docs.fleaflet.dev/layers/layer-interactivity
// ---------------------------------------------------------
                      child: PolygonLayer(
                        simplificationTolerance: 0, // do not simplify polygons, more precise, less performant
                        useAltRendering: true, // prevent artefacts, but less performant
                        polygons: buildPolygons(visibleBounds),
                        hitNotifier: hitNotifier,
                      ),
                    ),
                  );
                }
              )
            ],
          ),
        ],
      ),
    );
  }

  List<Polygon> buildPolygons(LatLngBounds? visibleBounds) {
    if (loadingData) return [];

    if (_cachedPolygonsObject[zoomLevel] == null) {
      int idx = 0;
      _cachedPolygonsObject[zoomLevel] = geoParsers[zoomLevel]!.polygons.map((polygon) {
        idx++;
        return Polygon(
          points: polygon.points,
          color: polygon.color,
          borderColor: polygon.borderColor,
          borderStrokeWidth: polygon.borderStrokeWidth,
          label: polygon.label,
          hitValue: idx, /// hit value paseed to the polygonLayer when the polygon is hit
        );
      }).toList();
    }

    /// here we track the visible polygons using visibleBounds (coordinates of the screen's edge)
    /// Then we sort the _cachedPolygons to return (and render) only the visiblePolygons
    if (visibleBounds == null) return _cachedPolygonsObject[zoomLevel]!;

    var visiblePolygons = _cachedPolygonsObject[zoomLevel]!
        .where((polygon) => isPolygonVisible(polygon, visibleBounds))
        .toList();
    print('visible polygons length: ${visiblePolygons.length}');
    print('cached polygons length: ${_cachedPolygonsObject[zoomLevel]!.length}');
    return visiblePolygons;
  }

  @override
  void initState() {
    // can be use to avoid some geometries to be displayed
    //geoParsers['simple']!.filterFunction = myFilterFunction;
    
    // Set loadingData to true to display loader while JSON is being processed
    loadingData = true;
    final Stopwatch stopwatch2 = Stopwatch()..start();
    processData().then((_) {
      setState(() { // setState allow tochange values similar to react
        loadingData = false;
      });
      print('GeoJson Processing time: ${stopwatch2.elapsed}');
    });
    super.initState();
  }

  bool myFilterFunction(Map<String, dynamic> properties) {
    // can be use to avoid some geometries to be displayed
    // it's usefull when u pull it from the web but probably not when pulled from a backend i guess
    if (properties['section'].toString().contains('Point M-4')) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> processData() async {
    // Here we should get the geojson from a back end where we store it
    final String geoJsonContent = await rootBundle.loadString('assets/geojsons/world_simplified.geojson');
    final String geoJsonContentDet = await rootBundle.loadString('assets/geojsons/world.geojson');

    geoParsers['simple']!.parseGeoJsonAsString(geoJsonContent);
    geoParsers['detailled']!.parseGeoJsonAsString(geoJsonContentDet);
  }
  
  void updateCameraZoom(MapCamera camera) {
    // If the zoom is the same as the previous one, we don't do anything
    // if the zoom pass a breakpoint we change the zoomLevel state
    // then update the new zoom state
    const int zoomBreakPoint = 3;
    print('Camera zoom: ${camera.zoom}');
    if (camera.zoom == mapZoom) return;

    if (camera.zoom < zoomBreakPoint && mapZoom > zoomBreakPoint) {
      setState(() {
        zoomLevel = 'simple';
      });
    } else if (camera.zoom > zoomBreakPoint && mapZoom < zoomBreakPoint) {
      setState(() {
        zoomLevel = 'detailled';
      });
    }

    setState(() {
      mapZoom = camera.zoom;
    });
  }

  void clearPolygonCache(String level) {
    /// Unsed yet but it good practice to have the ability to clean the cache if needed
    /// Maybe we'll need to use it to udpat the color of a polygon
    /// maybe we can just find the polygon in the _cachedPolygons and rebuild only this one.
    _cachedPolygonsObject[level] = null;
  }

  bool isPolygonVisible(Polygon polygon, LatLngBounds visibleBounds) {
    return polygon.points.any((point) {
      return visibleBounds.contains(point);
    });
  }
}
