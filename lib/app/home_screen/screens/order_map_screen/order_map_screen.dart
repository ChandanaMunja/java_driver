// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart' as flutter_map;
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:jippydriver_driver/app/home_screen/controller/home_controller.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:latlong2/latlong.dart' as latlng;

// class OrderMapScreen extends StatelessWidget {
//   const OrderMapScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.find<HomeController>();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Order Map'),
//         backgroundColor: AppThemeData.grey50,
//       ),
//       body: Constant.mapType == 'inappmap'
//           ? (Constant.selectedMapType == 'osm'
//               ? _OsmOrderMap(ctrl: ctrl)
//               : _GoogleOrderMap(ctrl: ctrl))
//           : const Center(
//               child: Text('In-app map is disabled in settings.'),
//             ),
//     );
//   }
// }

// class _GoogleOrderMap extends StatelessWidget {
//   final HomeController ctrl;
//   const _GoogleOrderMap({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() => GoogleMap(
//           onMapCreated: (c) => ctrl.mapController = c,
//           myLocationEnabled: true,
//           myLocationButtonEnabled: true,
//           zoomControlsEnabled: true,
//           mapType: MapType.normal,
//           markers: ctrl.markers.values.toSet(),
//           polylines: Set<Polyline>.of(ctrl.polyLines.values),
//           initialCameraPosition: CameraPosition(
//             zoom: 15,
//             target: LatLng(
//               ctrl.driverModel.value.location?.latitude ?? 0,
//               ctrl.driverModel.value.location?.longitude ?? 0,
//             ),
//           ),
//         ));
//   }
// }

// class _OsmOrderMap extends StatelessWidget {
//   final HomeController ctrl;
//   const _OsmOrderMap({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() => flutter_map.FlutterMap(
//           mapController: ctrl.osmMapController,
//           options: flutter_map.MapOptions(
//             initialCenter: latlng.LatLng(
//               ctrl.driverModel.value.location?.latitude ?? 0,
//               ctrl.driverModel.value.location?.longitude ?? 0,
//             ),
//             initialZoom: 13,
//             onMapReady: () => ctrl.setOsmMapReady(true),
//           ),
//           children: [
//             flutter_map.TileLayer(
//               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//               userAgentPackageName: 'com.example.app',
//             ),
//             flutter_map.MarkerLayer(markers: ctrl.osmMarkers),
//             if (ctrl.routePoints.isNotEmpty)
//               flutter_map.PolylineLayer(
//                 polylines: [
//                   flutter_map.Polyline(
//                     points: ctrl.routePoints,
//                     strokeWidth: 7,
//                     color: AppThemeData.secondary300,
//                   ),
//                 ],
//               ),
//           ],
//         ));
//   }
// }
