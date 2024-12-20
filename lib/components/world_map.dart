import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flt_app/components/territory.dart';
import 'package:latlong2/latlong.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({super.key});

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  final LayerHitNotifier hitNotifier = ValueNotifier(null);
  final int zoomBreakPoint = 3;
  
  double mapZoom = 0.0;
  String detailLevel = 'detailled';
  int territoryWatcher = 0;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: mapOptions(),
      children: [
        Builder(
          builder: (context) {
            // ignore: unused_local_variable
            final visibleBounds = MapCamera.of(context).visibleBounds;
            return MouseRegion(
              hitTestBehavior: HitTestBehavior.deferToChild,
              cursor: SystemMouseCursors.click, // change the appearance of the cursor
              child: GestureDetector(
                onTap: onTap,
                child:  PolygonLayer(
                  simplificationTolerance: 0, // do not simplify polygons, more precise, less performant
                  useAltRendering: true, // prevent artefacts, but less performant
                  polygons: buildTerritories(visibleBounds),
                  hitNotifier: hitNotifier,
                ) 
              ),
            ); 
          }
        ),
      ]
    );
  }

  MapOptions mapOptions() {
    /// Map options define the map position and behavior
      /// allow handle the camera limitation, and event directly on the map, and probably other things

      /// more about global event listening: https://docs.fleaflet.dev/usage/programmatic-interaction/listen-to-events
    return MapOptions(
      initialCenter: const LatLng(51.5, -0.09),
      initialZoom: 5,
      cameraConstraint: CameraConstraint.contain(
        bounds: LatLngBounds(
          const LatLng(-90, -180),
          const LatLng(90, 180),
        ),
      ),
      onPositionChanged: (camera, hasGesture) => onPositionChanged(camera),
      onTap: (_, __) => hitNotifier.value = null,
    );
  }

  void onTap() {
    final LayerHitResult? hitResult = hitNotifier.value;
    if (hitResult == null) return;
    
    print('${hitResult.hitValues}');

    Territory tappedTerritory = Territory.getById(hitResult.hitValues[0] as int);
    List<Territory> targets = Territory.getWhereIso3(tappedTerritory.iso3);
    

    for (var target in targets) {
      print('${target.getIso3()} - ${target.getId()}');
      Territory(
        id: target.getId(),
        points: target.getPoints(),
        color: Colors.red,
        borderColor: target.getBorderColor(),
        borderStrokeWidth: target.getBorderStrokeWidth(),
        iso3: target.getIso3(),
        detailLevel: target.getDetailLevel(),
        label: target.getLabel(),
        holePointsList: target.getHolePointsList(),
      );
    }

    setState(() =>
      territoryWatcher += 1
    );
  }

  void onPositionChanged(MapCamera camera) {
    // If the zoom is the same as the previous one, we don't do anything
    // if the zoom pass a breakpoint we change the detailLevel state
    // then update the new zoom state
    print('Camera zoom: ${camera.zoom}');
    if (camera.zoom == mapZoom) return;

    if (camera.zoom < zoomBreakPoint && mapZoom > zoomBreakPoint) {
      setState(() {
        detailLevel = 'simple';
      });
    } else if (camera.zoom > zoomBreakPoint && mapZoom < zoomBreakPoint) {
      setState(() {
        detailLevel = 'detailled';
      });
    }

    setState(() {
      mapZoom = camera.zoom;
    });
  }

  List<Territory> buildTerritories(LatLngBounds? visibleBounds) {
    if (visibleBounds == null) return Territory.getByDetail(detailLevel);

    var visibleTerritories = Territory.getByDetail(detailLevel)
      .where((territory) => territory.isVisible(visibleBounds))
      .toList();
    //print('visible polygons length: ${visibleTerritories.length}');
    //print('cached polygons length: ${Territory.getByDetail(detailLevel).length}');
    
    return visibleTerritories;
  }
}
