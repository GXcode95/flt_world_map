import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flt_app/misc/geojson_parser.dart';

import 'package:flt_app/components/world_map.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {  
  bool loadingData = false;

  Map<String, GeoJsonParser> geoParsers = {
    'simple': GeoJsonParser(
      geoJsonDetails: 'simple',
      defaultTerritoryBorderColor: const Color.fromARGB(255, 73, 54, 244),
      defaultTerritoryFillColor: const Color.fromARGB(255, 54, 206, 244).withOpacity(0.2),
    ),

    'detailled': GeoJsonParser(
      geoJsonDetails: 'detailled',
      defaultTerritoryBorderColor: const Color.fromARGB(255, 73, 54, 244),
      defaultTerritoryFillColor: const Color.fromARGB(255, 55, 233, 0).withOpacity(0.2),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          loadingData ? const Text('Loading') : WorldMap(geoDatas: geoParsers),
        ],
      ),
    );
  }

  @override
  void initState() {
    loadingData = true;
    final Stopwatch stopwatch2 = Stopwatch()..start();
    processData().then((_) {
      setState(() {
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
  
}
