// //
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:developer';
// // import 'package:android_pip/android_pip.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:jippydriver_driver/app/chat_screens/chat_screen.dart';
// // import 'package:jippydriver_driver/app/home_screen/screens/delivery_order_screen/deliver_order_screen.dart';
// // import 'package:jippydriver_driver/app/home_screen/screens/pickup_order_screen/pickup_order_screen.dart';
// // import 'package:jippydriver_driver/constant/constant.dart';
// // import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
// // import 'package:jippydriver_driver/controllers/dash_board_controller.dart';
// // import 'package:jippydriver_driver/app/home_screen/controller/home_controller.dart';
// // import 'package:jippydriver_driver/controllers/edit_profile_controller.dart';
// // import 'package:jippydriver_driver/main.dart';
// // import 'package:jippydriver_driver/models/order_model.dart';
// // import 'package:jippydriver_driver/models/user_model.dart';
// // import 'package:jippydriver_driver/services/audio_player_service.dart';
// // import 'package:jippydriver_driver/services/http_client_service.dart';
// // import 'package:jippydriver_driver/themes/app_them_data.dart';
// // import 'package:jippydriver_driver/themes/responsive.dart';
// // import 'package:jippydriver_driver/themes/round_button_fill.dart';
// // import 'package:jippydriver_driver/utils/app_logger.dart';
// // import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// // import 'package:jippydriver_driver/utils/fire_store_utils.dart';
// // import 'package:jippydriver_driver/utils/utils.dart';
// // import 'package:jippydriver_driver/widget/my_separator.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart' as flutterMap;
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:get/get.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:latlong2/latlong.dart' as location;
// // import 'package:provider/provider.dart';
// // import 'package:timelines_plus/timelines_plus.dart';
// // import '../order_list_screen/order_details_screen.dart';
// //
// //
// // final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
// //
// // class HomeScreen extends StatefulWidget {
// //   final bool? isAppBarShow;
// //   const HomeScreen({super.key, this.isAppBarShow});
// //
// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }
// //
// // class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver{
// //
// //   Timer? _pipDelayTimer; // Delay timer to prevent accidental PiP triggers
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);
// //   }
// //
// //   @override
// //   void dispose() {
// //     // Cancel PiP delay timer
// //     _pipDelayTimer?.cancel();
// //     // Remove lifecycle observer
// //     WidgetsBinding.instance.removeObserver(this);
// //     super.dispose();
// //   }
// //
// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     final controller = Get.find<HomeController>();
// //
// //     // Update polling optimization based on lifecycle state (includes cache cleanup)
// //     controller.updateAppLifecycleState(state);
// //
// //     // Smart PiP mode: Only enter PiP if:
// //     // 1. App is paused/inactive (user switched apps)
// //     // 2. Current route is active
// //     // 3. There's an active order (makes PiP useful)
// //     // 4. Add small delay to prevent accidental triggers
// //     if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive)
// //         && ModalRoute.of(context)?.isCurrent == true) {
// //       // Check if there's an active order before entering PiP
// //       final hasActiveOrder = controller.currentOrder.value.id != null &&
// //           controller.currentOrder.value.driverID == Constant.userModel?.id;
// //
// //       if (hasActiveOrder) {
// //         // Cancel any existing timer
// //         _pipDelayTimer?.cancel();
// //
// //         // Add 1 second delay before entering PiP to prevent accidental triggers
// //         _pipDelayTimer = Timer(const Duration(seconds: 1), () {
// //           if (mounted && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive)) {
// //             enterPipMode();
// //           }
// //         });
// //       } else {
// //         // No active order, don't enter PiP
// //         isInPipMode.value = false;
// //       }
// //     } else if (state == AppLifecycleState.resumed && ModalRoute.of(context)?.isCurrent == true) {
// //       // Cancel any pending PiP entry
// //       _pipDelayTimer?.cancel();
// //
// //       // Exit PiP mode when app resumes
// //       exitPipMode();
// //       AppLogger.log('App resumed - triggering immediate order refresh', tag: 'Lifecycle');
// //       controller.forceRefreshOrders();
// //     } else {
// //       // Cancel timer and reset PiP state
// //       _pipDelayTimer?.cancel();
// //       isInPipMode.value = false;
// //     }
// //   }
// //
// //   /// Enter PiP mode with optimized aspect ratio for better UX
// //   /// Aspect ratio options:
// //   /// - [1, 1] = Square (best for small screens, most visible)
// //   /// - [4, 3] = Medium (balanced)
// //   /// - [16, 9] = Wide (bigger but may be too wide)
// //   /// - [7, 9] = Tall (old, too small)
// //   Future<void> enterPipMode() async {
// //     // Prevent multiple PiP entries
// //     if (isInPipMode.value) {
// //       AppLogger.log('PiP mode already active, skipping', tag: 'PiP');
// //       return;
// //     }
// //
// //     try {
// //       // Using [1, 1] square aspect ratio for better visibility and user-friendliness
// //       // Square format is more visible and easier to interact with in PiP mode
// //       await AndroidPIP().enterPipMode(aspectRatio: [1, 1]);
// //
// //       // Use a small delay before setting flag for smooth transition
// //       await Future.delayed(const Duration(milliseconds: 300));
// //
// //       if (mounted) {
// //         isInPipMode.value = true;
// //         AppLogger.log('✅ PiP mode entered successfully with square aspect ratio [1, 1]', tag: 'PiP');
// //       }
// //     } catch (e) {
// //       debugPrint("Error entering PiP: $e");
// //       AppLogger.log('❌ Failed to enter PiP: $e', tag: 'PiP');
// //       // Reset flag on error
// //       isInPipMode.value = false;
// //     }
// //   }
// //
// //   /// Exit PiP mode smoothly
// //   Future<void> exitPipMode() async {
// //     try {
// //       // Note: Android PiP doesn't have a direct programmatic exit method
// //       // The system handles exit when user taps outside or app resumes
// //       // But we can reset the flag for smooth UI transition
// //       if (isInPipMode.value) {
// //         isInPipMode.value = false;
// //         AppLogger.log('✅ PiP mode exited', tag: 'PiP');
// //       }
// //     } catch (e) {
// //       debugPrint("Error exiting PiP: $e");
// //     }
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     final themeChange = Provider.of<DarkThemeProvider>(context);
// //     AppLogger.log('HomeScreen build() called', tag: 'Screen');
// //     return GetX(
// //       init: HomeController(),
// //       builder: (controller) {
// //         return Scaffold(
// //           appBar: widget.isAppBarShow == true
// //               ? AppBar(
// //                   backgroundColor: themeChange.getThem()
// //                       ? AppThemeData.grey900
// //                       : AppThemeData.grey50,
// //                   centerTitle: false,
// //                   iconTheme: const IconThemeData(
// //                       color: AppThemeData.grey900, size: 20),
// //                   title: Text(
// //                     "Order".tr,
// //                     style: TextStyle(
// //                         color: themeChange.getThem()
// //                             ? AppThemeData.grey50
// //                             : AppThemeData.grey900,
// //                         fontSize: 18,
// //                         fontFamily: AppThemeData.medium),
// //                   ),
// //                 )
// //               : null,
// //           body: controller.isLoading.value
// //               ? Constant.loader()
// //               : Constant.userModel?.vendorID?.isEmpty == true &&
// //                       Constant.isDriverVerification == true &&
// //                       Constant.userModel?.isDocumentVerify == false
// //                   ? Padding(
// //                       padding: const EdgeInsets.symmetric(horizontal: 16),
// //                       child: Column(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         crossAxisAlignment: CrossAxisAlignment.center,
// //                         children: [
// //                           Container(
// //                             decoration: ShapeDecoration(
// //                               color: themeChange.getThem()
// //                                   ? AppThemeData.grey700
// //                                   : AppThemeData.grey200,
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(120),
// //                               ),
// //                             ),
// //                             child: Padding(
// //                               padding: const EdgeInsets.all(20),
// //                               child: SvgPicture.asset(
// //                                   "assets/icons/ic_document.svg"),
// //                             ),
// //                           ),
// //                           const SizedBox(
// //                             height: 12,
// //                           ),
// //                           Text(
// //                             "Document Verification in Pending".tr,
// //                             style: TextStyle(
// //                                 color: themeChange.getThem()
// //                                     ? AppThemeData.grey100
// //                                     : AppThemeData.grey800,
// //                                 fontSize: 22,
// //                                 fontFamily: AppThemeData.semiBold),
// //                           ),
// //                           const SizedBox(
// //                             height: 5,
// //                           ),
// //                           Text(
// //                             "Your documents are being reviewed. We will notify you once the verification is complete."
// //                                 .tr,
// //                             textAlign: TextAlign.center,
// //                             style: TextStyle(
// //                                 color: themeChange.getThem()
// //                                     ? AppThemeData.grey50
// //                                     : AppThemeData.grey500,
// //                                 fontSize: 16,
// //                                 fontFamily: AppThemeData.bold,),
// //                           ),
// //                           const SizedBox(
// //                             height: 20,
// //                           ),
// //                           RoundedButtonFill(
// //                             title: "View Status".tr,
// //                             width: 55,
// //                             height: 5.5,
// //                             color: AppThemeData.secondary300,
// //                             textColor: AppThemeData.grey50,
// //                             onPress: () async {
// //                               DashBoardController dashBoardController =
// //                                   Get.put(DashBoardController());
// //                               dashBoardController.drawerIndex.value = 4;
// //                             },
// //                           ),
// //                         ],
// //                       ),
// //                     )
// //                   : Column(
// //                       children: [
// //                         Constant.userModel?.vendorID?.isEmpty == true &&
// //                                 double.parse(
// //                                         Constant.userModel!.walletAmount == null
// //                                             ? "0.0"
// //                                             : Constant.userModel!.walletAmount
// //                                                 .toString()) <
// //                                     double.parse(
// //                                         Constant.minimumDepositToRideAccept)
// //                             ? Padding(
// //                                 padding: const EdgeInsets.all(8.0),
// //                                 child: Text(
// //                                   "${'Please Contact your fleet manager your balance reached'.tr} ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept.toString())}",
// //                                   style: TextStyle(
// //                                       color: themeChange.getThem()
// //                                           ? AppThemeData.grey50
// //                                           : AppThemeData.grey900,
// //                                       fontSize: 14,
// //                                       fontFamily: AppThemeData.semiBold),
// //                                   textAlign: TextAlign.center,
// //                                 ),
// //                               )
// //                             : const SizedBox(),
// //                         Expanded(
// //                           child: Constant.mapType == "inappmap"
// //                               ? Constant.selectedMapType == "osm"
// //                                   ? Obx(() => flutterMap.FlutterMap(
// //                                         mapController:
// //                                             controller.osmMapController,
// //                                         options: flutterMap.MapOptions(
// //                                           initialCenter: location.LatLng(
// //                                               // Constant.locationDataFinal
// //                                               //         ?.latitude ??
// //                                               //     0.0,
// //                                               // Constant.locationDataFinal
// //                                               //         ?.longitude ??
// //                                               //     0.0
// //                                               controller.driverModel.value
// //                                                       .location?.latitude ??
// //                                                   0.0,
// //                                               controller.driverModel.value
// //                                                       .location?.longitude ??
// //                                                   0.0),
// //                                           initialZoom: 12,
// //                                           onMapReady: () {
// //                                             // Mark map as ready when it's rendered
// //                                             controller.setOsmMapReady(true);
// //                                           },
// //                                         ),
// //                                         children: [
// //                                           flutterMap.TileLayer(
// //                                             urlTemplate:
// //                                                 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
// //                                             userAgentPackageName:
// //                                                 'com.example.app',
// //                                           ),
// //                                           flutterMap.MarkerLayer(
// //                                               markers: controller.currentOrder
// //                                                           .value.id ==
// //                                                       null
// //                                                   ? []
// //                                                   : controller.osmMarkers),
// //                                           if (controller
// //                                                   .routePoints.isNotEmpty &&
// //                                               controller
// //                                                       .currentOrder.value.id !=
// //                                                   null)
// //                                             flutterMap.PolylineLayer(
// //                                               polylines: [
// //                                                 flutterMap.Polyline(
// //                                                   points:
// //                                                       controller.routePoints,
// //                                                   strokeWidth: 7.0,
// //                                                   color:
// //                                                       AppThemeData.secondary300,
// //                                                 ),
// //                                               ],
// //                                             ),
// //                                         ],
// //                                       ))
// //                                   : GoogleMap(
// //                             onMapCreated: (mapController) async {
// //                               controller.mapController = mapController;
// //                               // Reduced delay for faster initial camera setup
// //                               await Future.delayed(const Duration(milliseconds: 300));
// //                               // Only set initial camera position once - focus on driver location (bike), not start point
// //                               // Use driver location for initial camera position (bike position)
// //                               if (!controller.hasInitialCameraSet) {
// //                                 final driverLocation = controller.driverModel.value.location;
// //                                 if (driverLocation != null &&
// //                                     (driverLocation.latitude ?? 0.0) != 0.0 &&
// //                                     (driverLocation.longitude ?? 0.0) != 0.0) {
// //                                   controller.mapController!.animateCamera(
// //                                     CameraUpdate.newCameraPosition(
// //                                       CameraPosition(
// //                                         target: LatLng(
// //                                           driverLocation.latitude ?? 0.0,
// //                                           driverLocation.longitude ?? 0.0
// //                                         ),
// //                                         zoom: 15,
// //                                       ),
// //                                     ),
// //                                   );
// //                                   controller.hasInitialCameraSet = true;
// //                                 } else {
// //                                   // Fallback to Constant.locationDataFinal if driver location not available
// //                                   final location = Constant.locationDataFinal;
// //                                   if (location != null &&
// //                                       (location.latitude ?? 0.0) != 0.0 &&
// //                                       (location.longitude ?? 0.0) != 0.0) {
// //                                     controller.mapController!.animateCamera(
// //                                       CameraUpdate.newCameraPosition(
// //                                         CameraPosition(
// //                                           target: LatLng(
// //                                             location.latitude ?? 0.0,
// //                                             location.longitude ?? 0.0
// //                                           ),
// //                                           zoom: 15,
// //                                         ),
// //                                       ),
// //                                     );
// //                                     controller.hasInitialCameraSet = true;
// //                                   }
// //                                 }
// //                               }
// //                             },
// //                              // onMapCreated: (mapController) {
// //                                       //   controller.mapController =
// //                                       //       mapController;
// //                                       //   controller.mapController!.animateCamera(
// //                                       //     CameraUpdate.newCameraPosition(
// //                                       //       CameraPosition(
// //                                       //           target: LatLng(
// //                                       //               Constant.locationDataFinal
// //                                       //                       ?.latitude ??
// //                                       //                   0.0,
// //                                       //               Constant.locationDataFinal
// //                                       //                       ?.longitude ??
// //                                       //                   0.0),
// //                                       //           zoom: 15,
// //                                       //           bearing: double.parse(
// //                                       //               '${controller.driverModel.value.rotation ?? '0.0'}')),
// //                                       //     ),
// //                                       //   );
// //                                       // },
// //                                       myLocationEnabled:
// //                                           controller.currentOrder.value.id !=
// //                                                       null &&
// //                                                   controller.currentOrder.value
// //                                                           .status ==
// //                                                       Constant.driverPending
// //                                               ? false
// //                                               : true,
// //                                       myLocationButtonEnabled: true,
// //                                       mapType: MapType.normal,
// //                                       zoomControlsEnabled: true,
// //                                       polylines: Set<Polyline>.of(
// //                                           controller.polyLines.values),
// //                                       markers:
// //                                           controller.markers.values.toSet(),
// //                                       initialCameraPosition: CameraPosition(
// //                                         zoom: 15,
// //                                         target: LatLng(
// //                                             controller.driverModel.value
// //                                                     .location?.latitude ??
// //                                                 0.0,
// //                                             controller.driverModel.value
// //                                                     .location?.longitude ??
// //                                                 0.0),
// //                                       ),
// //
// //                                     )
// //                               : Padding(
// //                                   padding: const EdgeInsets.symmetric(
// //                                       horizontal: 16),
// //                                   child: Column(
// //                                     mainAxisAlignment: MainAxisAlignment.center,
// //                                     crossAxisAlignment:
// //                                         CrossAxisAlignment.center,
// //                                     children: [
// //                                       SvgPicture.asset(
// //                                           "assets/images/ic_location_map.svg"),
// //                                       const SizedBox(
// //                                         height: 10,
// //                                       ),
// //                                       Text(
// //                                         "${'Navigate with'.tr} ${Constant.mapType == "google" ? "Google Map" : Constant.mapType == "googleGo" ? "Google Go" : Constant.mapType == "waze" ? "Waze Map" : Constant.mapType == "mapswithme" ? "MapsWithMe Map" : Constant.mapType == "yandexNavi" ? "VandexNavi Map" : Constant.mapType == "yandexMaps" ? "Vandex Map" : ""}",
// //                                         style: TextStyle(
// //                                             color: themeChange.getThem()
// //                                                 ? AppThemeData.grey50
// //                                                 : AppThemeData.grey900,
// //                                             fontSize: 22,
// //                                             fontFamily: AppThemeData.semiBold),
// //                                       ),
// //                                       Text(
// //                                         "${'Easily find your destination with a single tap redirect to'.tr}  ${Constant.mapType == "google" ? "Google Map" : Constant.mapType == "googleGo" ? "Google Go" : Constant.mapType == "waze" ? "Waze Map" : Constant.mapType == "mapswithme" ? "MapsWithMe Map" : Constant.mapType == "yandexNavi" ? "VandexNavi Map" : Constant.mapType == "yandexMaps" ? "Vandex Map" : ""} ${'for seamless navigation.'.tr}",
// //                                         textAlign: TextAlign.center,
// //                                         style: TextStyle(
// //                                             color: themeChange.getThem()
// //                                                 ? AppThemeData.grey50
// //                                                 : AppThemeData.grey900,
// //                                             fontSize: 16,
// //                                             fontFamily: AppThemeData.regular),
// //                                       ),
// //                                       const SizedBox(
// //                                         height: 30,
// //                                       ),
// //                                       RoundedButtonFill(
// //                                         title:
// //                                             "${'Redirect'} ${Constant.mapType == "google" ? "Google Map" : Constant.mapType == "googleGo" ? "Google Go" : Constant.mapType == "waze" ? "Waze Map" : Constant.mapType == "mapswithme" ? "MapsWithMe Map" : Constant.mapType == "yandexNavi" ? "VandexNavi Map" : Constant.mapType == "yandexMaps" ? "Vandex Map" : ""}"
// //                                                 .tr,
// //                                         width: 55,
// //                                         height: 5.5,
// //                                         color: AppThemeData.driverApp300,
// //                                         textColor: AppThemeData.grey50,
// //                                         onPress: () async {
// //                                           if (controller
// //                                                   .currentOrder.value.id !=
// //                                               null) {
// //                                             if (controller.currentOrder.value
// //                                                     .status !=
// //                                                 Constant.driverPending) {
// //                                               if (controller.currentOrder.value
// //                                                       .status ==
// //                                                   Constant.orderShipped) {
// //                                                 Utils.redirectMap(
// //                                                     name: controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .vendor!
// //                                                         .title
// //                                                         .toString(),
// //                                                     latitude: controller
// //                                                             .currentOrder
// //                                                             .value
// //                                                             .vendor!
// //                                                             .latitude ??
// //                                                         0.0,
// //                                                     longLatitude: controller
// //                                                             .currentOrder
// //                                                             .value
// //                                                             .vendor!
// //                                                             .longitude ??
// //                                                         0.0);
// //                                               } else if (controller.currentOrder
// //                                                       .value.status ==
// //                                                   Constant.orderInTransit) {
// //                                                 Utils.redirectMap(
// //                                                     name: controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .author!
// //                                                         .firstName
// //                                                         .toString(),
// //                                                     latitude: controller
// //                                                             .currentOrder
// //                                                             .value
// //                                                             .address!
// //                                                             .location!
// //                                                             .latitude ??
// //                                                         0.0,
// //                                                     longLatitude: controller
// //                                                             .currentOrder
// //                                                             .value
// //                                                             .address!
// //                                                             .location!
// //                                                             .longitude ??
// //                                                         0.0);
// //                                               }
// //                                             } else {
// //                                               Utils.redirectMap(
// //                                                   name: controller.currentOrder
// //                                                       .value.author!.firstName
// //                                                       .toString(),
// //                                                   latitude: controller
// //                                                           .currentOrder
// //                                                           .value
// //                                                           .vendor!
// //                                                           .latitude ??
// //                                                       0.0,
// //                                                   longLatitude: controller
// //                                                           .currentOrder
// //                                                           .value
// //                                                           .vendor!
// //                                                           .longitude ??
// //                                                       0.0);
// //                                             }
// //                                           }
// //                                         },
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                         ),
// //                         // (controller.currentOrder.value.id != null &&
// //                         //     controller.currentOrder.value.status ==
// //                         //         Constant.driverPending &&
// //                         //     (controller.currentOrder.value.driverID ==
// //                         //             null ||
// //                         //         controller.currentOrder.value.driverID
// //                         //                 ?.isEmpty ==
// //                         //             true))
// //                         //     ? showDriverBottomSheet(themeChange, controller)
// //                         //     : (controller.currentOrder.value.id != null &&
// //                         //         controller.currentOrder.value.status !=
// //                         //             Constant.driverPending &&
// //                         //         controller.currentOrder.value.driverID ==
// //                         //             Constant.userModel?.id)
// //                         //         ? (() {
// //                         //             AppLogger.log(
// //                         //                 'Showing buildOrderActionsCard: currentDriverId=${Constant.userModel?.id}, orderDriverId=${controller.currentOrder.value.driverID}',
// //                         //                 tag: 'UI');
// //                         //             return buildOrderActionsCard(
// //                         //                 themeChange, controller);
// //                         //           })()
// //                         //         : (() {
// //                         //             // No active order: clear the map and show a message
// //                         //             controller.clearMap();
// //                         //             return Center(
// //                         //               child: Text(
// //                         //                 'No active orders. Waiting for new orders...',
// //                         //                 style: TextStyle(
// //                         //                     fontSize: 18, color: Colors.grey),
// //                         //               ),
// //                         //             );
// //                         //           })(),
// // Obx(
// //   () {
// //     bool isPiPActive = isInPipMode.value;
// //
// //     // In PiP mode, show simplified UI with essential info only
// //     if (isPiPActive) {
// //       return AnimatedSwitcher(
// //         duration: const Duration(milliseconds: 300),
// //         transitionBuilder: (Widget child, Animation<double> animation) {
// //           return FadeTransition(
// //             opacity: animation,
// //             child: child,
// //           );
// //         },
// //         child: Container(
// //           key: const ValueKey('pip_view'),
// //           child: buildOrderActionsCard(themeChange, controller),
// //         ),
// //       );
// //     }
// //
// //     // Normal full-screen UI
// //     // Check if order is in orderRequestData (pending driver acceptance)
// //     final isOrderInRequestData = controller.driverModel.value.orderRequestData
// //         ?.contains(controller.currentOrder.value.id) ?? false;
// //     // Show accept/reject bottom sheet if:
// //     // 1. Order exists
// //     // 2. Order is in orderRequestData OR status is Driver Pending (even if not in array yet - handles timing issues)
// //     // 3. No driver assigned yet
// //     // 4. Address is not null (required for bottom sheet)
// //     // 5. Vendor exists OR vendorID exists (vendor can be fetched if missing)
// //     // IMPORTANT: Also show if order has "Order Accepted" or "Driver Pending" status with no driver
// //     // This handles timing issues where order exists but Cloud Function hasn't updated orderRequestData yet
// //     final orderStatus = controller.currentOrder.value.status;
// //     final hasDriverPendingStatus = orderStatus == Constant.driverPending;
// //     final hasOrderAcceptedStatus = orderStatus == Constant.orderAccepted || orderStatus == "Order Accepted";
// //     final shouldShowAcceptReject = controller.currentOrder.value.id != null &&
// //         (isOrderInRequestData ||
// //          hasDriverPendingStatus ||
// //          (hasOrderAcceptedStatus && (controller.currentOrder.value.driverID == null || controller.currentOrder.value.driverID?.isEmpty == true))) &&
// //         (controller.currentOrder.value.driverID == null ||
// //             controller.currentOrder.value.driverID?.isEmpty == true) &&
// //         controller.currentOrder.value.address != null &&
// //         (controller.currentOrder.value.vendor != null ||
// //          (controller.currentOrder.value.vendorID != null &&
// //           controller.currentOrder.value.vendorID!.isNotEmpty));
// //
// //     // Log UI state for debugging (only when order exists)
// //     if (controller.currentOrder.value.id != null) {
// //       AppLogger.log(
// //           'UI State - OrderID: ${controller.currentOrder.value.id}, '
// //           'Status: ${controller.currentOrder.value.status}, '
// //           'DriverID: ${controller.currentOrder.value.driverID}, '
// //           'CurrentDriverID: ${Constant.userModel?.id}, '
// //           'isOrderInRequestData: $isOrderInRequestData, '
// //           'shouldShowAcceptReject: $shouldShowAcceptReject',
// //           tag: 'UI');
// //     }
// //
// //     // Show order card if:
// //     // 1. Should show accept/reject bottom sheet (new order request)
// //     // 2. Order exists, driverID matches current driver, and status is NOT driverPending (active order)
// //     // 3. Order exists, driverID matches current driver, and status IS driverPending (driver assigned but still pending)
// //     final shouldShowOrderCard = controller.currentOrder.value.id != null &&
// //         controller.currentOrder.value.driverID == Constant.userModel?.id &&
// //         (!isOrderInRequestData || controller.currentOrder.value.status == Constant.driverPending);
// //
// //     return AnimatedSwitcher(
// //       duration: const Duration(milliseconds: 300),
// //       transitionBuilder: (Widget child, Animation<double> animation) {
// //         return FadeTransition(
// //           opacity: animation,
// //           child: child,
// //         );
// //       },
// //       child: shouldShowAcceptReject
// //           ? Container(
// //               key: const ValueKey('accept_reject'),
// //               child: showDriverBottomSheet(themeChange, controller),
// //             )
// //           : shouldShowOrderCard
// //               ? Container(
// //                   key: const ValueKey('order_card'),
// //                   child: (() {
// //                     AppLogger.log(
// //                         'Showing buildOrderActionsCard: currentDriverId=${Constant.userModel?.id}, orderDriverId=${controller.currentOrder.value.driverID}, status=${controller.currentOrder.value.status}',
// //                         tag: 'UI');
// //                     return buildOrderActionsCard(themeChange, controller);
// //                   })(),
// //                 )
// //               : Container(
// //                   key: const ValueKey('no_order'),
// //                   child: (() {
// //                     /// Clear the map ONLY if the current driver is NOT assigned
// //                     if (controller.currentOrder.value.driverID != Constant.userModel?.id) {
// //                       controller.clearMap();
// //                     }
// //                     AppLogger.log(
// //                         'Not showing order card - OrderID: ${controller.currentOrder.value.id}, '
// //                         'Status: ${controller.currentOrder.value.status}, '
// //                         'DriverID match: ${controller.currentOrder.value.driverID == Constant.userModel?.id}, '
// //                         'isOrderInRequestData: $isOrderInRequestData',
// //                         tag: 'UI');
// //                     return SafeArea(
// //                       child: Center(
// //                         // child: Text(
// //                         //   'No active orders. Waiting for new orders...',
// //                         //   style: TextStyle(
// //                         //       fontSize: 18, color: Colors.grey),
// //                         // ),
// //                       ),
// //                     );
// //                   })(),
// //                 ),
// //     );
// //   }
// // ),
// //
// //                         // Obx(() {
// //                         //   if (controller.currentOrder.value.id == null) {
// //                         //     return Container(); // No active order
// //                         //   } else if (controller.currentOrder.value.status ==
// //                         //       Constant.driverPending) {
// //                         //     return showDriverBottomSheet(
// //                         //         themeChange, controller);
// //                         //   } else if (controller.currentOrder.value.status ==
// //                         //       Constant.orderShipped) {
// //                         //     // Don't show PickupOrderScreen inline - let the button handle navigation
// //                         //     return Container();
// //                         //   } else if (controller.currentOrder.value.status ==
// //                         //       Constant.orderInTransit) {
// //                         //     return DeliverOrderScreen();
// //                         //   }
// //                         //   else if (controller.currentOrder.value.status ==
// //                         //       Constant.orderCompleted) {
// //                         //     return Center(child: Text('Order Completed'));
// //                         //   }
// //                         //   else {
// //                         //     // Don't show buildOrderActionsCard inline to prevent overflow
// //                         //     // The bottom navigation bar will handle the actions
// //                         //     return Container();
// //                         //   }
// //                         // }),
// //                       ],
// //                     ),
// //
// //           // bottomNavigationBar: Obx(() {
// //           //   // Show button for all active orders except pending and completed
// //           //   if (controller.currentOrder.value.id == null ||
// //           //       controller.currentOrder.value.status ==
// //           //           Constant.driverPending ||
// //           //       controller.currentOrder.value.status ==
// //           //           Constant.orderCompleted ||
// //           //       controller.currentOrder.value.status ==
// //           //           Constant.driverRejected) {
// //           //     return SizedBox.shrink();
// //           //   }
// //           //
// //           //   String buttonText;
// //           //   VoidCallback? onTap;
// //           //
// //           //   if (controller.currentOrder.value.status == Constant.orderShipped ||
// //           //       controller.currentOrder.value.status ==
// //           //           Constant.driverAccepted) {
// //           //     buttonText = "Reached restaurant for Pickup".tr;
// //           //     onTap = () {
// //           //       Get.to(const PickupOrderScreen(), arguments: {
// //           //         "orderModel": controller.currentOrder.value
// //           //       })?.then((v) async {
// //           //         if (v == true) {
// //           //           OrderModel? ordermodel = await FireStoreUtils.getOrderById(
// //           //               controller.currentOrder.value.id!);
// //           //           if (ordermodel?.id != null) {
// //           //             controller.currentOrder.value = ordermodel!;
// //           //           }
// //           //           controller.update();
// //           //         }
// //           //       });
// //           //     };
// //           //   } else if (controller.currentOrder.value.status ==
// //           //       Constant.orderInTransit) {
// //           //     buttonText =
// //           //         controller.driverModel.value.vendorID?.isEmpty == true
// //           //             ? "Reached the Customers Door Steps".tr
// //           //             : "Order Delivered".tr;
// //           //     onTap = () {
// //           //       Get.to(const DeliverOrderScreen(), arguments: {
// //           //         "orderModel": controller.currentOrder.value
// //           //       })?.then((value) async {
// //           //         if (value == true) {
// //           //           await AudioPlayerService.playSound(false);
// //           //           controller.driverModel.value.inProgressOrderID!
// //           //               .remove(controller.currentOrder.value.id);
// //           //           await FireStoreUtils.updateUser(
// //           //               controller.driverModel.value);
// //           //           controller.currentOrder.value = OrderModel();
// //           //           controller.clearMap();
// //           //           if (Constant.singleOrderReceive == false) {
// //           //             Get.back();
// //           //           }
// //           //         }
// //           //       });
// //           //     };
// //           //   } else {
// //           //     // For any other status, show a generic action button
// //           //     buttonText = "View Order Details".tr;
// //           //     onTap = () {
// //           //       // Show order details or handle other statuses
// //           //       Get.snackbar(
// //           //         "Order Status",
// //           //         "Current status: ${controller.currentOrder.value.status}",
// //           //         snackPosition: SnackPosition.BOTTOM,
// //           //         duration: Duration(seconds: 3),
// //           //       );
// //           //     };
// //           //   }
// //           //   return InkWell(
// //           //     onTap: onTap,
// //           //     child: Container(
// //           //       color: AppThemeData.driverApp300,
// //           //       width: Responsive.width(100, Get.context ?? context),
// //           //       child: Padding(
// //           //         padding: const EdgeInsets.symmetric(vertical: 16),
// //           //         child: Text(
// //           //           buttonText,
// //           //           textAlign: TextAlign.center,
// //           //           style: TextStyle(
// //           //             color: themeChange.getThem()
// //           //                 ? AppThemeData.grey900
// //           //                 : AppThemeData.grey900,
// //           //             fontSize: 16,
// //           //             fontFamily: AppThemeData.semiBold,
// //           //             fontWeight: FontWeight.w400,
// //           //           ),
// //           //         ),
// //           //       ),
// //           //     ),
// //           //   );
// //           // }),
// //           // bottomNavigationBar: Obx(() {
// //           //   if (controller.currentOrder.value.id == null) {
// //           //     return SizedBox.shrink();
// //           //   }
// //           //   String buttonText;
// //           //   VoidCallback? onTap;
// //           //   if (controller.currentOrder.value.status == Constant.orderShipped ||
// //           //       controller.currentOrder.value.status == Constant.driverAccepted) {
// //           //     buttonText = "Reached restaurant for Pickup".tr;
// //           //     onTap = () {
// //           //       Get.to(const PickupOrderScreen(), arguments: {
// //           //         "orderModel": controller.currentOrder.value
// //           //       })?.then((v) async {
// //           //         if (v == true) {
// //           //           OrderModel? ordermodel = await FireStoreUtils.getOrderById(
// //           //               controller.currentOrder.value.id!);
// //           //           if (ordermodel?.id != null) {
// //           //             controller.currentOrder.value = ordermodel!;
// //           //           }
// //           //           controller.update();
// //           //         }
// //           //       });
// //           //     };
// //           //   } else {
// //           //     buttonText = controller.driverModel.value.vendorID?.isEmpty == true
// //           //         ? "Reached the Customers Door Steps".tr
// //           //         : "Order Delivered".tr;
// //           //     onTap = () {
// //           //       Get.to(const DeliverOrderScreen(), arguments: {
// //           //         "orderModel": controller.currentOrder.value
// //           //       })?.then((value) async {
// //           //         if (value == true) {
// //           //           await AudioPlayerService.playSound(false);
// //           //           controller.driverModel.value.inProgressOrderID!
// //           //               .remove(controller.currentOrder.value.id);
// //           //           await FireStoreUtils.updateUser(
// //           //               controller.driverModel.value);
// //           //           controller.currentOrder.value = OrderModel();
// //           //           controller.clearMap();
// //           //           if (Constant.singleOrderReceive == false) {
// //           //             Get.back();
// //           //           }
// //           //         }
// //           //       });
// //           //     };
// //           //   }
// //           //   return InkWell(
// //           //     onTap: onTap,
// //           //     child: Container(
// //           //       color: AppThemeData.driverApp300,
// //           //       width: Responsive.width(100, Get.context ?? context),
// //           //       child: Padding(
// //           //         padding: const EdgeInsets.symmetric(vertical: 16),
// //           //         child: Text(
// //           //           buttonText,
// //           //           textAlign: TextAlign.center,
// //           //           style: TextStyle(
// //           //             color: themeChange.getThem()
// //           //                 ? AppThemeData.grey900
// //           //                 : AppThemeData.grey900,
// //           //             fontSize: 16,
// //           //             fontFamily: AppThemeData.semiBold,
// //           //             fontWeight: FontWeight.w400,
// //           //           ),
// //           //         ),
// //           //       ),
// //           //     ),
// //           //   );
// //           // }),
// //         );
// //       },
// //     );
// //   }
// //
// //
// //
// //   showDriverBottomSheet(themeChange, HomeController controller) {
// //     // Ensure charges are calculated when showing bottom sheet
// //     if (controller.currentOrder.value.id != null) {
// //       controller.calculateOrderChargesInitial();
// //     }
// //
// //     // Add null checks before calculating distance
// //     final vendor = controller.currentOrder.value.vendor;
// //     final address = controller.currentOrder.value.address;
// //     final location = address?.location;
// //     double distanceInMeters = 0.0;
// //     if (vendor != null && location != null) {
// //       distanceInMeters = Geolocator.distanceBetween(
// //           vendor.latitude ?? 0.0,
// //           vendor.longitude ?? 0.0,
// //           location.latitude ?? 0.0,
// //           location.longitude ?? 0.0);
// //     }
// //     double kilometer = distanceInMeters / 1000;
// //     return Padding(
// //       padding: const EdgeInsets.all(8.0),
// //       child: Container(
// //         decoration: ShapeDecoration(
// //           color: themeChange.getThem()
// //               ? AppThemeData.grey900
// //               : AppThemeData.grey50,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(16),
// //           ),
// //         ),
// //         child: Padding(
// //           padding: const EdgeInsets.all(8.0),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Timeline.tileBuilder(
// //                 shrinkWrap: true,
// //                 padding: EdgeInsets.zero,
// //                 physics: const NeverScrollableScrollPhysics(),
// //                 theme: TimelineThemeData(
// //                   nodePosition: 0,
// //                 ),
// //                 builder: TimelineTileBuilder.connected(
// //                   contentsAlign: ContentsAlign.basic,
// //                   indicatorBuilder: (context, index) {
// //                     return index == 0
// //                         ? Container(
// //                             decoration: ShapeDecoration(
// //                               color: AppThemeData.primary50,
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(120),
// //                               ),
// //                             ),
// //                             child: Padding(
// //                               padding: const EdgeInsets.all(10),
// //                               child: SvgPicture.asset(
// //                                 "assets/icons/ic_building.svg",
// //                                 colorFilter: const ColorFilter.mode(
// //                                     AppThemeData.primary300, BlendMode.srcIn),
// //                               ),
// //                             ),
// //                           )
// //                         : Container(
// //                             decoration: ShapeDecoration(
// //                               color: AppThemeData.driverApp50,
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(120),
// //                               ),
// //                             ),
// //                             child: Padding(
// //                               padding: const EdgeInsets.all(10),
// //                               child: SvgPicture.asset(
// //                                 "assets/icons/ic_location.svg",
// //                                 colorFilter: ColorFilter.mode(
// //                                     AppThemeData.driverApp300, BlendMode.srcIn),
// //                               ),
// //                             ),
// //                           );
// //                   },
// //                   connectorBuilder: (context, index, connectorType) {
// //                     return const DashedLineConnector(
// //                       color: AppThemeData.grey300,
// //                       gap: 3,
// //                     );
// //                   },
// //                   contentsBuilder: (context, index) {
// //                     return Padding(
// //                       padding: const EdgeInsets.symmetric(
// //                           horizontal: 10, vertical: 10),
// //                       child: index == 0
// //                           ? Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   "${vendor?.title ?? 'N/A'}",
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.semiBold,
// //                                     fontSize: 16,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey50
// //                                         : AppThemeData.grey900,
// //                                   ),
// //                                 ),
// //                                 Text(
// //                                   "${vendor?.location ?? 'N/A'}",
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.medium,
// //                                     fontSize: 14,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey300
// //                                         : AppThemeData.grey600,
// //                                   ),
// //                                 ),
// //                               ],
// //                             )
// //                           : Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   "Deliver to the".tr,
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.semiBold,
// //                                     fontSize: 16,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey50
// //                                         : AppThemeData.grey900,
// //                                   ),
// //                                 ),
// //                                 Text(
// //                                   address?.getFullAddress() ?? 'N/A',
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.medium,
// //                                     fontSize: 14,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey300
// //                                         : AppThemeData.grey600,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                     );
// //                   },
// //                   itemCount: 2,
// //                 ),
// //               ),
// //               Padding(
// //                 padding: const EdgeInsets.symmetric(vertical: 5),
// //                 child: MySeparator(
// //                     color: themeChange.getThem()
// //                         ? AppThemeData.grey700
// //                         : AppThemeData.grey200),
// //               ),
// //
// //               FutureBuilder<double?>(
// //                 future: fetchOrderSurgeFee(
// //                     controller.currentOrder.value.id.toString()),
// //                 builder: (context, snapshot) {
// //                   final surgeFee = snapshot.data ?? 0.0;
// //                   final hasSurge = surgeFee > 0;
// //               // FutureBuilder<Map<String, dynamic>?>(
// //               //   future: _getCalculatedCharges(controller),
// //               //   builder: (context, snapshot) {
// //               //     final charges = snapshot.data;
// //               //     final hasCalculatedCharges = charges != null;
// //                   return Column(
// //                     children: [
// //                       // Surge Fee Badge - Only show when there's surge
// //                       // if (hasSurge)
// //                       //   Container(
// //                       //     width: double.infinity,
// //                       //     padding: const EdgeInsets.symmetric(
// //                       //         vertical: 8, horizontal: 12),
// //                       //     margin: const EdgeInsets.only(bottom: 10),
// //                       //     decoration: BoxDecoration(
// //                       //       // color: AppThemeData.warning50.withOpacity(0.2),
// //                       //       color: Color(0xffff5200),
// //                       //       border: Border.all(
// //                       //         color: AppThemeData.warning300,
// //                       //         width: 1,
// //                       //       ),
// //                       //       borderRadius: BorderRadius.circular(8),
// //                       //     ),
// //                       //     child: Row(
// //                       //       mainAxisAlignment: MainAxisAlignment.center,
// //                       //       children: [
// //                       //         Icon(
// //                       //           Icons.bolt_rounded,
// //                       //           color: AppThemeData.warning500,
// //                       //           size: 18,
// //                       //         ),
// //                       //         const SizedBox(width: 6),
// //                       //         Text(
// //                       //           "High Demand Area".tr,
// //                       //           style: TextStyle(
// //                       //             fontFamily: AppThemeData.semiBold,
// //                       //             fontSize: 14,
// //                       //             color: AppThemeData.warning600,
// //                       //           ),
// //                       //         ),
// //                       //         const SizedBox(width: 6),
// //                       //         Text(
// //                       //           "+${surgeFee.toStringAsFixed(2)}",
// //                       //           style: TextStyle(
// //                       //             fontFamily: AppThemeData.bold,
// //                       //             fontSize: 14,
// //                       //             color: AppThemeData.warning600,
// //                       //           ),
// //                       //         ),
// //                       //       ],
// //                       //     ),
// //                       //   ),
// //                       // Trip Distance
// //                       Row(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Expanded(
// //                             child: Text(
// //                               "Trip Distance".tr,
// //                               textAlign: TextAlign.start,
// //                               style: TextStyle(
// //                                 fontFamily: AppThemeData.regular,
// //                                 color: themeChange.getThem()
// //                                     ? AppThemeData.grey300
// //                                     : AppThemeData.grey600,
// //                                 fontSize: 16,
// //                               ),
// //                             ),
// //                           ),
// //                           Text(
// //                             "${double.parse(kilometer.toString()).toStringAsFixed(2)} ${Constant.distanceType}",
// //                             textAlign: TextAlign.start,
// //                             style: TextStyle(
// //                               fontFamily: AppThemeData.semiBold,
// //                               color: themeChange.getThem()
// //                                   ? AppThemeData.grey50
// //                                   : AppThemeData.grey900,
// //                               fontSize: 16,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //
// //                       // NEW: Restaurant to Customer Charge
// //
// //                       // const SizedBox(height: 8),
// //                       // if (hasCalculatedCharges) ...[
// //                       //   _buildChargeBreakdownRow(
// //                       //     "To Restaurant:",
// //                       //     "${charges['driverToRestaurantDistance']?.toStringAsFixed(2) ?? '0.00'} km",
// //                       //     "+₹${charges['driverToRestaurantCharge']?.toStringAsFixed(2) ?? '0.00'}",
// //                       //     themeChange,
// //                       //   ),
// //                       //   _buildChargeBreakdownRow(
// //                       //     "To Customer:",
// //                       //     "${charges['restaurantToCustomerDistance']?.toStringAsFixed(2) ?? '0.00'} km",
// //                       //     "+₹${charges['restaurantToCustomerCharge']?.toStringAsFixed(2) ?? '0.00'}",
// //                       //     themeChange,
// //                       //   ),
// //                       //   const SizedBox(height: 8),
// //                       //   Container(
// //                       //     padding: const EdgeInsets.all(8),
// //                       //     decoration: BoxDecoration(
// //                       //       color: AppThemeData.success50.withOpacity(0.2),
// //                       //       borderRadius: BorderRadius.circular(8),
// //                       //       border: Border.all(color: AppThemeData.success200),
// //                       //     ),
// //                       //     child: Row(
// //                       //       children: [
// //                       //         Expanded(
// //                       //           child: Text(
// //                       //             "Total Calculated:".tr,
// //                       //             style: TextStyle(
// //                       //               fontFamily: AppThemeData.semiBold,
// //                       //               color: themeChange.getThem()
// //                       //                   ? AppThemeData.grey50
// //                       //                   : AppThemeData.grey900,
// //                       //               fontSize: 16,
// //                       //             ),
// //                       //           ),
// //                       //         ),
// //                       //         Text(
// //                       //           "₹${charges['totalCalculatedCharge']?.toStringAsFixed(2) ?? '0.00'}",
// //                       //           style: TextStyle(
// //                       //             fontFamily: AppThemeData.bold,
// //                       //             color: AppThemeData.success500,
// //                       //             fontSize: 18,
// //                       //           ),
// //                       //         ),
// //                       //       ],
// //                       //     ),
// //                       //   ),
// //                       //   const SizedBox(height: 8),
// //                       // ],
// //                       controller.currentOrder.value.tipAmount == null ||
// //                           controller.currentOrder.value.tipAmount!.isEmpty ||
// //                           double.parse(controller.currentOrder.value.tipAmount
// //                               .toString()) <=
// //                               0
// //                           ? const SizedBox()
// //                           : Row(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Expanded(
// //                             child: Text(
// //                               "Tips".tr,
// //                               textAlign: TextAlign.start,
// //                               style: TextStyle(
// //                                 fontFamily: AppThemeData.regular,
// //                                 color: themeChange.getThem()
// //                                     ? AppThemeData.grey300
// //                                     : AppThemeData.grey600,
// //                                 fontSize: 16,
// //                               ),
// //                             ),
// //                           ),
// //                           Text(
// //                             Constant.amountShow(
// //                                 amount:
// //                                 controller.currentOrder.value.tipAmount ??
// //                                     "0.0"),
// //                             textAlign: TextAlign.start,
// //                             style: TextStyle(
// //                               fontFamily: AppThemeData.semiBold,
// //                               color: themeChange.getThem()
// //                                   ? AppThemeData.grey50
// //                                   : AppThemeData.grey900,
// //                               fontSize: 16,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(
// //                         height: 10,
// //                       ),
// //                       // Delivery Charge
// //                       Visibility(
// //                         visible:
// //                             (controller.driverModel.value.vendorID?.isEmpty ==
// //                                 true),
// //                         child: Column(children: [
// //                           Row(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Expanded(
// //                                 child: Text(
// //                                   "Delivery Charge".tr,
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.regular,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey300
// //                                         : AppThemeData.grey600,
// //                                     fontSize: 16,
// //                                   ),
// //                                 ),
// //                               ),
// //                               Text(
// //                                 // controller.totalCalculatedCharge.value > 0
// //                                 //     ?
// //                                 "${controller.driverToRestaurantCharge.value.toInt()} + ${controller.restaurantToCustomerCharge.value.toInt()} = ${controller.totalCalculatedCharge.value.toInt()}",
// //                                     // : Constant.amountShow(
// //                                     //     amount: (controller.currentOrder.value.deliveryCharge != null &&
// //                                     //             controller.currentOrder.value.deliveryCharge!.isNotEmpty &&
// //                                     //             double.tryParse(controller.currentOrder.value.deliveryCharge!) != null &&
// //                                     //             double.tryParse(controller.currentOrder.value.deliveryCharge!)! > 0)
// //                                     //         ? controller.currentOrder.value.deliveryCharge!
// //                                     //         : "0.0"),
// //                                 textAlign: TextAlign.start,
// //                                 style: TextStyle(
// //                                   fontFamily: AppThemeData.semiBold,
// //                                   color: themeChange.getThem()
// //                                       ? AppThemeData.grey50
// //                                       : AppThemeData.grey900,
// //                                   fontSize: 16,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                           const SizedBox(height: 8),
// //                         ]),
// //                       ),
// //                       if (hasSurge)
// //                       Container(
// //                         padding: const EdgeInsets.symmetric(
// //                             vertical: 6, horizontal: 8),
// //                         decoration: BoxDecoration(
// //                           color:
// //                           hasSurge
// //                               ? AppThemeData.success50.withOpacity(0.3)
// //                               :
// //                           Colors.transparent,
// //                           borderRadius: BorderRadius.circular(6),
// //                         ),
// //                         child: Row(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Expanded(
// //                               child: Row(
// //                                 children: [
// //                                   Text(
// //                                     "Surge Fee".tr,
// //                                     textAlign: TextAlign.start,
// //                                     style: TextStyle(
// //                                       fontFamily: AppThemeData.regular,
// //                                       color: themeChange.getThem()
// //                                           ? AppThemeData.grey300
// //                                           : AppThemeData.grey600,
// //                                       fontSize: 16,
// //                                     ),
// //                                   ),
// //                                   if (hasSurge) const SizedBox(width: 6),
// //                                   if (hasSurge)
// //                                     Icon(
// //                                       Icons.trending_up_rounded,
// //                                       color: AppThemeData.success400,
// //                                       size: 16,
// //                                     ),
// //                                 ],
// //                               ),
// //                             ),
// //                             Text(
// //                               "+${surgeFee.toStringAsFixed(2)}",
// //                               textAlign: TextAlign.start,
// //                               style: TextStyle(
// //                                 fontFamily: AppThemeData.semiBold,
// //                                 color: hasSurge
// //                                     ? AppThemeData.success500
// //                                     : (themeChange.getThem()
// //                                         ? AppThemeData.grey50
// //                                         : AppThemeData.grey900),
// //                                 fontSize: hasSurge ? 17 : 16,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //
// //                       // Total Earnings Estimate - New Section
// //                         Column(
// //                           children: [
// //                             const SizedBox(height: 8),
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(
// //                                   vertical: 8, horizontal: 12),
// //                               decoration: BoxDecoration(
// //                                 color: AppThemeData.primary50.withOpacity(0.2),
// //                                 borderRadius: BorderRadius.circular(8),
// //                                 border: Border.all(
// //                                   color: AppThemeData.primary200,
// //                                   width: 1,
// //                                 ),
// //                               ),
// //                               child: Row(
// //                                 children: [
// //                                   Expanded(
// //                                     child: Text(
// //                                       "Total Earnings".tr,
// //                                       textAlign: TextAlign.start,
// //                                       style: TextStyle(
// //                                         fontFamily: AppThemeData.semiBold,
// //                                         color: themeChange.getThem()
// //                                             ? AppThemeData.grey50
// //                                             : AppThemeData.grey900,
// //                                         fontSize: 16,
// //                                       ),
// //                                     ),
// //                                   ),
// //                                   //finded
// //                                   Text(
// //                                     "${(
// //                                         (double.tryParse(controller.currentOrder.value.tipAmount?.toString() ?? '0') ?? 0.0)
// //                                             +
// //                                             (controller.totalCalculatedCharge.value > 0
// //                                                 ? controller.totalCalculatedCharge.value
// //                                                 : 0.0)
// //                                             +
// //                                             surgeFee
// //                                     ).toInt()}",
// //                                     // "${((double.tryParse(controller.currentOrder.value.tipAmount?.toString() ?? '0') ?? 0.0) +
// //                                     //     (controller.totalCalculatedCharge.value > 0
// //                                     //         ? controller.totalCalculatedCharge.value
// //                                     //         :
// //                                     //     (controller.currentOrder.value.deliveryCharge != null &&
// //                                     //            controller.currentOrder.value.deliveryCharge!.isNotEmpty &&
// //                                     //            double.tryParse(controller.currentOrder.value.deliveryCharge!) != null)
// //                                     //             ? double.tryParse(controller.currentOrder.value.deliveryCharge!)!
// //                                     //             : 0.0)
// //                                     //     +
// //                                     //     surgeFee).toInt()}",
// //                                     textAlign: TextAlign.start,
// //                                     style: TextStyle(
// //                                       fontFamily: AppThemeData.bold,
// //                                       color: AppThemeData.primary500,
// //                                       fontSize: 18,
// //                                     ),
// //                                   ),
// //                                   // Text(
// //                                   //   "${double.parse(controller.currentOrder.value.tipAmount
// //                                   //       .toString())+ controller.totalCalculatedCharge.value + (surgeFee)}",
// //                                   //   textAlign: TextAlign.start,
// //                                   //   style: TextStyle(
// //                                   //     fontFamily: AppThemeData.bold,
// //                                   //     color: AppThemeData.primary500,
// //                                   //     fontSize: 18,
// //                                   //   ),
// //                                   // ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                     ],
// //                   );
// //                 },
// //               ),
// //
// //               const SizedBox(height: 8),
// //
// //               // Tips Section
// //               // controller.currentOrder.value.tipAmount == null ||
// //               //         controller.currentOrder.value.tipAmount?.isEmpty ==
// //               //             true ||
// //               //         double.parse(controller.currentOrder.value.tipAmount
// //               //                     ?.toString() ??
// //               //                 "0.0") <=
// //               //             0
// //               //     ? const SizedBox()
// //               //     : Column(
// //               //         children: [
// //               //           Row(
// //               //             crossAxisAlignment: CrossAxisAlignment.start,
// //               //             children: [
// //               //               Expanded(
// //               //                 child: Text(
// //               //                   "Tips".tr,
// //               //                   textAlign: TextAlign.start,
// //               //                   style: TextStyle(
// //               //                     fontFamily: AppThemeData.regular,
// //               //                     color: themeChange.getThem()
// //               //                         ? AppThemeData.grey300
// //               //                         : AppThemeData.grey600,
// //               //                     fontSize: 16,
// //               //                   ),
// //               //                 ),
// //               //               ),
// //               //               Text(
// //               //                 Constant.amountShow(
// //               //                     amount:
// //               //                         controller.currentOrder.value.tipAmount),
// //               //                 textAlign: TextAlign.start,
// //               //                 style: TextStyle(
// //               //                   fontFamily: AppThemeData.semiBold,
// //               //                   color: themeChange.getThem()
// //               //                       ? AppThemeData.grey50
// //               //                       : AppThemeData.grey900,
// //               //                   fontSize: 16,
// //               //                 ),
// //               //               ),
// //               //             ],
// //               //           ),
// //               //           const SizedBox(height: 8),
// //               //         ],
// //               //       ),
// //
// //               const SizedBox(height: 10),
// //               // Action Buttons
// //               SafeArea(
// //                 child: Row(
// //                   children: [
// //                     Expanded(
// //                       child: RoundedButtonFill(
// //                         title: "Reject".tr,
// //                         width: 24,
// //                         height: 5.5,
// //                         borderRadius: 10,
// //                         color: AppThemeData.danger300,
// //                         textColor: AppThemeData.grey50,
// //                         onPress: () {
// //                           AppLogger.log('User clicked Reject Order button',
// //                               tag: 'UserAction');
// //                           controller.rejectOrder();
// //                         },
// //                       ),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     Expanded(
// //                       child: RoundedButtonFill(
// //                         title: "Accept".tr,
// //                         width: 24,
// //                         height: 5.5,
// //                         borderRadius: 10,
// //                         color: AppThemeData.success400,
// //                         textColor: AppThemeData.grey50,
// //                         onPress: () async {
// //                           AppLogger.log('User clicked Accept Order button',
// //                               tag: 'UserAction');
// //                           // acceptOrder() already handles all updates and UI refresh
// //                           // No need to fetch again - it will cause race conditions
// //                           await controller.acceptOrder();
// //                         },
// //                       ),
// //                     )
// //                   ],
// //                 ),
// //               ),
// //               const SizedBox(height: 10),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// Helper method to determine the correct delivery button text based on order status
// //   /// This method is called inside Obx() to ensure it reacts to status changes
// //   String _getDeliveryButtonText(HomeController controller) {
// //     // Access observable values to ensure reactivity
// //     final orderStatus = controller.currentOrder.value.status;
// //     final isDirectDelivery = controller.driverModel.value.vendorID?.isEmpty == true;
// //
// //     // Handle null or empty status
// //     if (orderStatus == null || orderStatus.isEmpty) {
// //       return "Order Delivered".tr;
// //     }
// //
// //     // Status priority check - ensure we show correct button based on actual status
// //     // Order progression: driverPending -> driverAccepted -> orderShipped -> orderInTransit -> orderCompleted
// //
// //     // Pickup stage: Order Shipped or Driver Accepted
// //     if (orderStatus == Constant.orderShipped ||
// //         orderStatus == Constant.driverAccepted ||
// //         orderStatus == "Order Shipped" ||
// //         orderStatus == "Driver Accepted") {
// //       return "Reached restaurant for Pickup".tr;
// //     }
// //
// //     // Delivery stage: In Transit
// //     if (orderStatus == Constant.orderInTransit ||
// //         orderStatus == "In Transit") {
// //       // Direct delivery (no restaurant) - customer pickup
// //       if (isDirectDelivery) {
// //         return "Reached the Customers Door Steps".tr;
// //       }
// //       // Restaurant delivery - mark as delivered
// //       return "Order Delivered".tr;
// //     }
// //
// //     // Order Completed - show delivered
// //     if (orderStatus == Constant.orderCompleted ||
// //         orderStatus == "Order Completed") {
// //       return "Order Delivered".tr;
// //     }
// //
// //     // Driver Pending - show pickup (order just accepted, waiting for driver)
// //     if (orderStatus == Constant.driverPending ||
// //         orderStatus == "Driver Pending") {
// //       return "Reached restaurant for Pickup".tr;
// //     }
// //
// //     // Fallback: Default to "Order Delivered" for any other status
// //     return "Order Delivered".tr;
// //   }
// //
// //   // showDriverBottomSheet(themeChange, HomeController controller) {
// //   buildOrderActionsCard(themeChange, HomeController controller) {
// //     double totalAmount = 0.0;
// //     double subTotal = 0.0;
// //     double taxAmount = 0.0;
// //     double specialDiscount = 0.0;
// //
// //     for (var element in controller.currentOrder.value.products!) {
// //       if (double.parse(element.discountPrice.toString()) <= 0) {
// //         subTotal = subTotal +
// //             double.parse(element.price.toString()) *
// //                 double.parse(element.quantity.toString()) +
// //             (double.parse(element.extrasPrice.toString()) *
// //                 double.parse(element.quantity.toString()));
// //       } else {
// //         subTotal = subTotal +
// //             double.parse(element.discountPrice.toString()) *
// //                 double.parse(element.quantity.toString()) +
// //             (double.parse(element.extrasPrice.toString()) *
// //                 double.parse(element.quantity.toString()));
// //       }
// //     }
// //
// //     if (controller.currentOrder.value.taxSetting != null) {
// //       for (var element in controller.currentOrder.value.taxSetting!) {
// //         taxAmount = taxAmount +
// //             Constant.calculateTax(
// //                 amount: (subTotal -
// //                         double.parse(
// //                             controller.currentOrder.value.discount.toString()))
// //                     .toString(),
// //                 taxModel: element);
// //       }
// //     }
// //
// //     if (controller.currentOrder.value.specialDiscount != null &&
// //         controller.currentOrder.value.specialDiscount!['special_discount'] !=
// //             null) {
// //       specialDiscount = double.parse(controller
// //           .currentOrder.value.specialDiscount!['special_discount']
// //           .toString());
// //     }
// //
// //     totalAmount = subTotal -
// //         double.parse(controller.currentOrder.value.discount.toString()) -
// //         specialDiscount +
// //         taxAmount +
// //         double.parse(controller.currentOrder.value.deliveryCharge.toString()) +
// //         double.parse(controller.currentOrder.value.tipAmount.toString());
// //
// //     return Container(
// //       color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
// //       child: Column(
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //
// //                 IconButton(onPressed: (){
// //                   controller.changeArrow();
// //                 }, icon: Icon(Icons.keyboard_arrow_down_rounded,),
// //                 ),
// //                 controller.arrowDrop.value?SizedBox():    controller.currentOrder.value.status == Constant.orderShipped ||
// //                         controller.currentOrder.value.status ==
// //                             Constant.driverAccepted
// //                     ? Row(
// //                         children: [
// //                           Container(
// //                             decoration: ShapeDecoration(
// //                               color: AppThemeData.primary50,
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(120),
// //                               ),
// //                             ),
// //                             child: Padding(
// //                               padding: const EdgeInsets.all(10),
// //                               child: SvgPicture.asset(
// //                                 "assets/icons/ic_building.svg",
// //                                 colorFilter: const ColorFilter.mode(
// //                                     AppThemeData.primary300, BlendMode.srcIn),
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(
// //                             width: 10,
// //                           ),
// //                           Expanded(
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   "${controller.currentOrder.value.vendor?.title}",
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.semiBold,
// //                                     fontSize: 16,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey50
// //                                         : AppThemeData.grey900,
// //                                   ),
// //                                 ),
// //                                 Text(
// //                                   "${controller.currentOrder.value.vendor?.location}",
// //                                   textAlign: TextAlign.start,
// //                                   style: TextStyle(
// //                                     fontFamily: AppThemeData.medium,
// //                                     fontSize: 14,
// //                                     color: themeChange.getThem()
// //                                         ? AppThemeData.grey300
// //                                         : AppThemeData.grey600,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                           const SizedBox(
// //                             width: 10,
// //                           ),
// //                           InkWell(
// //                             onTap: () {
// //                               Constant.makePhoneCall(controller
// //                                   .currentOrder.value.vendor!.phonenumber
// //                                   .toString());
// //                             },
// //                             child: Container(
// //                               width: 38,
// //                               height: 38,
// //                               decoration: ShapeDecoration(
// //                                 shape: RoundedRectangleBorder(
// //                                   side: BorderSide(
// //                                       width: 1,
// //                                       color: themeChange.getThem()
// //                                           ? AppThemeData.grey700
// //                                           : AppThemeData.grey200),
// //                                   borderRadius: BorderRadius.circular(120),
// //                                 ),
// //                               ),
// //                               child: Padding(
// //                                 padding: const EdgeInsets.all(8.0),
// //                                 child: SvgPicture.asset(
// //                                     "assets/icons/ic_phone_call.svg"),
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       )
// //                     : Timeline.tileBuilder(
// //                         /*
// //                   shrinkWrap: true,
// //                         padding: EdgeInsets.zero,
// //                         physics: const NeverScrollableScrollPhysics(),
// //                         theme: TimelineThemeData(
// //                           nodePosition: 0,
// //                           // indicatorPosition: 0,
// //                         ),
// //                         builder: TimelineTileBuilder.connected(
// //                           contentsAlign: ContentsAlign.basic,
// //                           indicatorBuilder: (context, index) {
// //                             return index == 0
// //                                 ? Container(
// //                                     decoration: ShapeDecoration(
// //                                       color: AppThemeData.primary50,
// //                                       shape: RoundedRectangleBorder(
// //                                         borderRadius:
// //                                             BorderRadius.circular(120),
// //                                       ),
// //                                     ),
// //                                     child: Padding(
// //                                       padding: const EdgeInsets.all(10),
// //                                       child: SvgPicture.asset(
// //                                         "assets/icons/ic_building.svg",
// //                                         colorFilter: const ColorFilter.mode(
// //                                             AppThemeData.primary300,
// //                                             BlendMode.srcIn),
// //                                       ),
// //                                     ),
// //                                   )
// //                                 : Container(
// //                                     decoration: ShapeDecoration(
// //                                       color: AppThemeData.driverApp50,
// //                                       shape: RoundedRectangleBorder(
// //                                         borderRadius:
// //                                             BorderRadius.circular(120),
// //                                       ),
// //                                     ),
// //                                     child: Padding(
// //                                       padding: const EdgeInsets.all(10),
// //                                       child: SvgPicture.asset(
// //                                       */
// //
// //                         shrinkWrap: true,
// //                         padding: EdgeInsets.zero,
// //                         physics: const NeverScrollableScrollPhysics(),
// //                         theme: TimelineThemeData(
// //                           nodePosition: 0,
// //                           // indicatorPosition: 0,
// //                         ),
// //                         builder: TimelineTileBuilder.connected(
// //                           contentsAlign: ContentsAlign.basic,
// //                           indicatorBuilder: (context, index) {
// //                             return index == 0
// //                                 ? Container(
// //                                     decoration: ShapeDecoration(
// //                                       color: AppThemeData.primary50,
// //                                       shape: RoundedRectangleBorder(
// //                                         borderRadius:
// //                                             BorderRadius.circular(120),
// //                                       ),
// //                                     ),
// //                                     child: Padding(
// //                                       padding: const EdgeInsets.all(10),
// //                                       child: SvgPicture.asset(
// //                                         "assets/icons/ic_building.svg",
// //                                         colorFilter: const ColorFilter.mode(
// //                                             AppThemeData.primary300,
// //                                             BlendMode.srcIn),
// //                                       ),
// //                                     ),
// //                                   )
// //                                 : Container(
// //                                     decoration: ShapeDecoration(
// //                                       color: AppThemeData.driverApp50,
// //                                       shape: RoundedRectangleBorder(
// //                                         borderRadius:
// //                                             BorderRadius.circular(120),
// //                                       ),
// //                                     ),
// //                                     child: Padding(
// //                                       padding: const EdgeInsets.all(10),
// //                                       child: SvgPicture.asset(
// //                                         "assets/icons/ic_location.svg",
// //                                         colorFilter: ColorFilter.mode(
// //                                             AppThemeData.driverApp300,
// //                                             BlendMode.srcIn),
// //                                       ),
// //                                     ),
// //                                   );
// //                           },
// //                           connectorBuilder: (context, index, connectorType) {
// //                             return const DashedLineConnector(
// //                               color: AppThemeData.grey300,
// //                               gap: 3,
// //                             );
// //                           },
// //                           contentsBuilder: (context, index) {
// //                             return Padding(
// //                               padding: const EdgeInsets.symmetric(
// //                                   horizontal: 10, vertical: 10),
// //                               child: index == 0
// //                                   ? Row(
// //                                       children: [
// //                                         Expanded(
// //                                           child: Column(
// //                                             crossAxisAlignment:
// //                                                 CrossAxisAlignment.start,
// //                                             children: [
// //                                               Text(
// //                                                 "${controller.currentOrder.value.vendor?.title}",
// //                                                 textAlign: TextAlign.start,
// //                                                 style: TextStyle(
// //                                                   fontFamily:
// //                                                       AppThemeData.semiBold,
// //                                                   fontSize: 16,
// //                                                   color: themeChange.getThem()
// //                                                       ? AppThemeData.grey50
// //                                                       : AppThemeData.grey900,
// //                                                 ),
// //                                               ),
// //                                               Text(
// //                                                 "${controller.currentOrder.value.vendor?.location}",
// //                                                 textAlign: TextAlign.start,
// //                                                 style: TextStyle(
// //                                                   fontFamily:
// //                                                       AppThemeData.medium,
// //                                                   fontSize: 14,
// //                                                   color: themeChange.getThem()
// //                                                       ? AppThemeData.grey300
// //                                                       : AppThemeData.grey600,
// //                                                 ),
// //                                               ),
// //                                             ],
// //                                           ),
// //                                         ),
// //                                         const SizedBox(
// //                                           width: 5,
// //                                         ),
// //                                         InkWell(
// //                                           onTap: () {
// //                                             Constant.makePhoneCall(controller
// //                                                 .currentOrder
// //                                                 .value
// //                                                 .vendor!
// //                                                 .phonenumber
// //                                                 .toString());
// //                                           },
// //                                           child: Container(
// //                                             width: 42,
// //                                             height: 42,
// //                                             decoration: ShapeDecoration(
// //                                               shape: RoundedRectangleBorder(
// //                                                 side: BorderSide(
// //                                                     width: 1,
// //                                                     color: themeChange.getThem()
// //                                                         ? AppThemeData.grey700
// //                                                         : AppThemeData.grey200),
// //                                                 borderRadius:
// //                                                     BorderRadius.circular(120),
// //                                               ),
// //                                             ),
// //                                             child: Padding(
// //                                               padding:
// //                                                   const EdgeInsets.all(8.0),
// //                                               child: SvgPicture.asset(
// //                                                   "assets/icons/ic_phone_call.svg"),
// //                                             ),
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     )
// //                                   : Row(
// //                                       children: [
// //                                         Expanded(
// //                                           child: Column(
// //                                             crossAxisAlignment:
// //                                                 CrossAxisAlignment.start,
// //                                             children: [
// //                                               Text(
// //                                                 "Deliver to the".tr,
// //                                                 textAlign: TextAlign.start,
// //                                                 style: TextStyle(
// //                                                   fontFamily:
// //                                                       AppThemeData.semiBold,
// //                                                   fontSize: 16,
// //                                                   color: themeChange.getThem()
// //                                                       ? AppThemeData.grey50
// //                                                       : AppThemeData.grey900,
// //                                                 ),
// //                                               ),
// //                                               Text(
// //                                                 controller
// //                                                     .currentOrder.value.address!
// //                                                     .getFullAddress(),
// //                                                 textAlign: TextAlign.start,
// //                                                 style: TextStyle(
// //                                                   fontFamily:
// //                                                       AppThemeData.medium,
// //                                                   fontSize: 14,
// //                                                   color: themeChange.getThem()
// //                                                       ? AppThemeData.grey300
// //                                                       : AppThemeData.grey600,
// //                                                 ),
// //                                               ),
// //                                             ],
// //                                           ),
// //                                         ),
// //                                         const SizedBox(
// //                                           width: 5,
// //                                         ),
// //                                         InkWell(
// //                                           onTap: () async {
// //                                             ShowToastDialog.showLoader(
// //                                                 "Please wait".tr);
// //
// //                                             UserModel? customer =
// //                                                 await FireStoreUtils
// //                                                     .getUserProfile(controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .authorID
// //                                                         .toString());
// //
// //                                             ShowToastDialog.closeLoader();
// //
// //                                             if (customer != null &&
// //                                                 customer.phoneNumber != null) {
// //                                               Constant.makePhoneCall(
// //                                                   customer.phoneNumber!);
// //                                             } else {
// //                                               ShowToastDialog.showToast(
// //                                                   "Customer phone number not available");
// //                                             }
// //                                           },
// //                                           child: Container(
// //                                             width: 42,
// //                                             height: 42,
// //                                             decoration: ShapeDecoration(
// //                                               shape: RoundedRectangleBorder(
// //                                                 side: BorderSide(
// //                                                     width: 1,
// //                                                     color: themeChange.getThem()
// //                                                         ? AppThemeData.grey700
// //                                                         : AppThemeData.grey200),
// //                                                 borderRadius:
// //                                                     BorderRadius.circular(120),
// //                                               ),
// //                                             ),
// //                                             child: Padding(
// //                                               padding:
// //                                                   const EdgeInsets.all(8.0),
// //                                               child: SvgPicture.asset(
// //                                                   "assets/icons/ic_phone_call.svg"),
// //                                             ),
// //                                           ),
// //                                         ),
// //                                         SizedBox(width: 8),
// //                                         InkWell(
// //                                           onTap: () async {
// //                                             ShowToastDialog.showLoader(
// //                                                 "Please wait".tr);
// //
// //                                             /*
// //
// //                                 UserModel? customer =
// //                                                 await FireStoreUtils
// //                                                     .getUserProfile(controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .authorID
// //                                                         .toString());
// //                                             UserModel? driver =
// //                                                 await FireStoreUtils
// //                                                     .getUserProfile(controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .driverID
// //                                                         .toString());
// //                                 */
// //                                             UserModel? customer =
// //                                                 await FireStoreUtils
// //                                                     .getUserProfile(controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .authorID
// //                                                         .toString());
// //                                             UserModel? driver =
// //                                                 await FireStoreUtils
// //                                                     .getUserProfile(controller
// //                                                         .currentOrder
// //                                                         .value
// //                                                         .driverID
// //                                                         .toString());
// //
// //                                             ShowToastDialog.closeLoader();
// //
// //                                             Get.to(const ChatScreen(),
// //                                                 arguments: {
// //                                                   "customerName":
// //                                                       '${customer!.fullName()}',
// //                                                   "restaurantName":
// //                                                       driver!.fullName(),
// //                                                   "orderId": controller
// //                                                       .currentOrder.value.id,
// //                                                   "restaurantId": driver.id,
// //                                                   "customerId": customer.id,
// //                                                   "customerProfileImage": customer
// //                                                           .profilePictureURL ??
// //                                                       "",
// //                                                   "restaurantProfileImage":
// //                                                       driver.profilePictureURL ??
// //                                                           "",
// //                                                   "token": customer.fcmToken,
// //                                                   "chatType": "Driver",
// //                                                 });
// //                                           },
// //                                           child: Container(
// //                                             width: 42,
// //                                             height: 42,
// //                                             decoration: ShapeDecoration(
// //                                               shape: RoundedRectangleBorder(
// //                                                 side: BorderSide(
// //                                                     width: 1,
// //                                                     color: themeChange.getThem()
// //                                                         ? AppThemeData.grey700
// //                                                         : AppThemeData.grey200),
// //                                                 borderRadius:
// //                                                     BorderRadius.circular(120),
// //                                               ),
// //                                             ),
// //                                             child: Padding(
// //                                               padding:
// //                                                   const EdgeInsets.all(8.0),
// //                                               child: SvgPicture.asset(
// //                                                   "assets/icons/ic_wechat.svg"),
// //                                             ),
// //                                           ),
// //                                         )
// //                                       ],
// //                                     ),
// //                             );
// //                           },
// //                           itemCount: 2,
// //                         ),
// //                       ),
// //                 Padding(
// //                   padding: const EdgeInsets.symmetric(vertical: 20),
// //                   child: MySeparator(
// //                       color: themeChange.getThem()
// //                           ? AppThemeData.grey700
// //                           : AppThemeData.grey200),
// //                 ),
// //                 Row(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Expanded(
// //                       child: Text(
// //                         "Payment Type".tr,
// //                         textAlign: TextAlign.start,
// //                         style: TextStyle(
// //                           fontFamily: AppThemeData.regular,
// //                           color: themeChange.getThem()
// //                               ? AppThemeData.grey300
// //                               : AppThemeData.grey600,
// //                           fontSize: 16,
// //                         ),
// //                       ),
// //                     ),
// //                     Text(
// //                       controller.currentOrder.value.paymentMethod
// //                                   ?.toLowerCase() ==
// //                               "cod"
// //                           ? "Cash on delivery"
// //                           : "Online",
// //                       textAlign: TextAlign.start,
// //                       style: TextStyle(
// //                         fontFamily: AppThemeData.semiBold,
// //                         color: themeChange.getThem()
// //                             ? AppThemeData.grey50
// //                             : AppThemeData.grey900,
// //                         fontSize: 16,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(
// //                   height: 5,
// //                 ),
// //                 controller.currentOrder.value.paymentMethod?.toLowerCase() ==
// //                         "cod"
// //                     ? Row(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Expanded(
// //                             child: Text(
// //                               "Collect Payment from customer".tr,
// //                               textAlign: TextAlign.start,
// //                               style: TextStyle(
// //                                 fontFamily: AppThemeData.regular,
// //                                 color: themeChange.getThem()
// //                                     ? AppThemeData.grey300
// //                                     : AppThemeData.grey600,
// //                                 fontSize: 16,
// //                               ),
// //                             ),
// //                           ),
// //                           // Cached ToPay amount display - prevents repeated API calls
// //                           _CachedToPayAmount(
// //                             orderId: controller.currentOrder.value.id!,
// //                             themeChange: themeChange,
// //                           ),
// //                         ],
// //                       )
// //                     : const SizedBox(),
// //                 const SizedBox(
// //                   height: 5,
// //                 ),
// //
// //               ],
// //             ),
// //           ),
// //           InkWell(
// //             onTap: () async {
// //               if (controller.currentOrder.value.status ==
// //                       Constant.orderShipped ||
// //                   controller.currentOrder.value.status ==
// //                       Constant.driverAccepted) {
// //                 log('\u001b[32mHomeScreen -> PickupOrderScreen\u001b[0m');
// //                 Get.to(const PickupOrderScreen(), arguments: {
// //                   "orderModel": controller.currentOrder.value
// //                 })?.then((v) async {
// //                   if (v == true) {
// //                     // Optimistically update status to orderInTransit for smooth transition
// //                     final cachedOrder = controller.currentOrder.value;
// //                     final orderId = cachedOrder.id;
// //
// //                     if (cachedOrder.status == Constant.driverAccepted ||
// //                         cachedOrder.status == Constant.orderShipped) {
// //                       cachedOrder.status = Constant.orderInTransit;
// //                       controller.currentOrder.value = cachedOrder;
// //                       controller.currentOrder.refresh();
// //                       AppLogger.log('✅ Optimistically updated status to orderInTransit for order: $orderId', tag: 'UI');
// //                     }
// //
// //                     // Force refresh from server (bypass cache) to get latest status
// //                     // Small delay to allow Firestore/API to update
// //                     await Future.delayed(Duration(milliseconds: 800));
// //                     await controller.refreshCurrentOrder(forceRefresh: true);
// //
// //                     controller.update();
// //                   }
// //                 });
// //               } else {
// //                 log('\u001b[32mHomeScreen -> DeliverOrderScreen\u001b[0m');
// //                 Get.to(const DeliverOrderScreen(), arguments: {
// //                   "orderModel": controller.currentOrder.value
// //                 })!
// //                     .then(
// //                   (value) async {
// //                     if (value == true || value is String) {
// //                       // Order delivery completed - clear everything (sound already played in DeliverOrderController)
// //                       // value can be orderId (String) if passed from DeliverOrderController, or true
// //                       final completedOrderId = (value is String ? value : null) ??
// //                           controller.currentOrder.value.id?.toString();
// //
// //                       if (completedOrderId != null) {
// //                         controller.markOrderAsCompleted(completedOrderId);
// //                         // Remove from inProgressOrderID and orderRequestData
// //                         controller.driverModel.value.inProgressOrderID
// //                             ?.removeWhere((id) => id?.toString() == completedOrderId);
// //                         controller.driverModel.value.orderRequestData
// //                             ?.removeWhere((id) => id?.toString() == completedOrderId);
// //                       }
// //
// //                       // Invalidate cache for completed order to prevent it from showing again
// //                       if (completedOrderId != null) {
// //                         final httpClient = HttpClientService();
// //                         await httpClient.invalidateCache('orders/$completedOrderId');
// //                         AppLogger.log('🗑️ Invalidated cache for completed order: $completedOrderId', tag: 'Order');
// //                       }
// //
// //                       // Update driver profile
// //                       await FireStoreUtils.updateUser(controller.driverModel.value);
// //
// //                       // Clear current order immediately
// //                       controller.currentOrder.value = OrderModel();
// //                       controller.clearMap();
// //
// //                       // Reset status tracking
// //                       controller.resetStatusTracking();
// //
// //                       // Force UI update
// //                       controller.update();
// //
// //                       AppLogger.log('✅ Order delivery completed - order cleared: $completedOrderId', tag: 'Order');
// //
// //                       if (Constant.singleOrderReceive == false) {
// //                         Get.back();
// //                       }
// //                     }
// //                   },
// //                 );
// //               }
// //             },
// //             child: SafeArea(
// //               child: Container(
// //                 color: AppThemeData.driverApp300,
// //                 width: Responsive.width(100, Get.context!),
// //                 child: Padding(
// //                   padding: const EdgeInsets.symmetric(vertical: 16),
// //                   child: Obx(() => AnimatedSwitcher(
// //                     duration: const Duration(milliseconds: 300),
// //                     transitionBuilder: (Widget child, Animation<double> animation) {
// //                       return FadeTransition(
// //                         opacity: animation,
// //                         child: SlideTransition(
// //                           position: Tween<Offset>(
// //                             begin: const Offset(0.0, 0.1),
// //                             end: Offset.zero,
// //                           ).animate(CurvedAnimation(
// //                             parent: animation,
// //                             curve: Curves.easeOut,
// //                           )),
// //                           child: child,
// //                         ),
// //                       );
// //                     },
// //                     child: Text(
// //                       _getDeliveryButtonText(controller),
// //                       key: ValueKey<String>(_getDeliveryButtonText(controller)),
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(
// //                         color: themeChange.getThem()
// //                             ? AppThemeData.grey900
// //                             : AppThemeData.grey900,
// //                         fontSize: 16,
// //                         fontFamily: AppThemeData.semiBold,
// //                         fontWeight: FontWeight.w400,
// //                       ),
// //                     ),
// //                   )),
// //                 ),
// //               ),
// //             ),
// //           )
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class HomeScreenLogger extends RouteAware {
// //   @override
// //   void didPush() {
// //     AppLogger.log('Navigated to HomeScreen', tag: 'Screen');
// //   }
// //
// //   @override
// //   void didPop() {
// //     AppLogger.log('Popped HomeScreen', tag: 'Screen');
// //   }
// // }
// //
// // /// Cached widget to prevent repeated API calls for ToPay amount
// // class _CachedToPayAmount extends StatefulWidget {
// //   final String orderId;
// //   final dynamic themeChange; // DarkThemeProvider
// //
// //   const _CachedToPayAmount({
// //     required this.orderId,
// //     required this.themeChange,
// //   });
// //
// //   @override
// //   State<_CachedToPayAmount> createState() => _CachedToPayAmountState();
// // }
// //
// // class _CachedToPayAmountState extends State<_CachedToPayAmount> {
// //   Future<double?>? _cachedFuture;
// //   String? _lastOrderId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchToPay();
// //   }
// //
// //   @override
// //   void didUpdateWidget(_CachedToPayAmount oldWidget) {
// //     super.didUpdateWidget(oldWidget);
// //     // Only refetch if order ID changed
// //     if (oldWidget.orderId != widget.orderId) {
// //       _fetchToPay();
// //     }
// //   }
// //
// //   void _fetchToPay() {
// //     if (_lastOrderId != widget.orderId) {
// //       _lastOrderId = widget.orderId;
// //       _cachedFuture = fetchToPayForOrder(widget.orderId);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return FutureBuilder<double?>(
// //       future: _cachedFuture,
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const SizedBox(
// //             width: 24,
// //             height: 24,
// //             child: CircularProgressIndicator(strokeWidth: 2),
// //           );
// //         }
// //         if (snapshot.hasError) {
// //           return const Text('Error');
// //         }
// //         final toPay = snapshot.data;
// //         return Text(
// //           Constant.amountShow(amount: (toPay ?? 0.0).toString()),
// //           textAlign: TextAlign.start,
// //           style: TextStyle(
// //             fontFamily: AppThemeData.semiBold,
// //             color: widget.themeChange.getThem()
// //                 ? AppThemeData.grey50
// //                 : AppThemeData.grey900,
// //             fontSize: 16,
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // Future<double?> fetchOrderSurgeFee(String orderId) async {
// //   try {
// //     final url = '${Constant.baseUrl}mobile/orders/$orderId/billing/surge-fee';
// //     print("fetchOrderSurgeFee $url");
// //     final response = await http.get(Uri.parse(url));
// //     print(" fetchOrderSurgeFee ${response.body}");
// //     if (response.statusCode == 200) {
// //       final Map<String, dynamic> jsonResponse = json.decode(response.body);
// //       final totalSurgeFee = jsonResponse['data']?['total_surge_fee'];
// //       if (jsonResponse['success'] == true && totalSurgeFee != null) {
// //         return (totalSurgeFee is num) ? totalSurgeFee.toDouble() : double.tryParse(totalSurgeFee.toString());
// //       }
// //     } else {
// //       print('Failed to fetch surge fee. Status code: ${response.statusCode}');
// //     }
// //   } catch (e) {
// //     print('Error fetching surge fee: $e');
// //   }
// //   return null;
// // }
// // class ShiningHighDemandWidget extends StatefulWidget {
// //   final double surgeFee;
// //
// //   const ShiningHighDemandWidget({super.key, required this.surgeFee});
// //
// //   @override
// //   State<ShiningHighDemandWidget> createState() =>
// //       _ShiningHighDemandWidgetState();
// // }
// //
// // class _ShiningHighDemandWidgetState extends State<ShiningHighDemandWidget>
// //     with SingleTickerProviderStateMixin {
// //   late AnimationController _controller;
// //   late Animation<Color?> _colorAnimation;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(
// //       duration: const Duration(milliseconds: 2000),
// //       vsync: this,
// //     )..repeat(reverse: true);
// //
// //     _colorAnimation = ColorTween(
// //       begin: AppThemeData.warning300,
// //       end: Colors.orange.shade600,
// //     ).animate(CurvedAnimation(
// //       parent: _controller,
// //       curve: Curves.easeInOut,
// //     ));
// //   }
// //
// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return AnimatedBuilder(
// //       animation: _colorAnimation,
// //       builder: (context, child) {
// //         return Container(
// //           width: double.infinity,
// //           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
// //           margin: const EdgeInsets.only(bottom: 10),
// //           decoration: BoxDecoration(
// //             color: Colors.orange,
// //             border: Border.all(
// //               color: _colorAnimation.value!,
// //               width: 2, // Slightly thicker border for emphasis
// //             ),
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Icon(
// //                 Icons.bolt_rounded,
// //                 color: AppThemeData.warning500,
// //                 size: 18,
// //               ),
// //               const SizedBox(width: 6),
// //               Text(
// //                 "High Demand Area".tr,
// //                 style: TextStyle(
// //                   fontFamily: AppThemeData.semiBold,
// //                   fontSize: 14,
// //                   color: AppThemeData.warning600,
// //                 ),
// //               ),
// //               const SizedBox(width: 6),
// //               Text(
// //                 "+${widget.surgeFee.toStringAsFixed(2)}",
// //                 style: TextStyle(
// //                   fontFamily: AppThemeData.bold,
// //                   fontSize: 14,
// //                   color: AppThemeData.warning600,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
// //
// //
// // // NEW: Helper widget for charge breakdown rows
//
//
//
// // ============================================================
// //  home_screen_optimized.dart
// //  Drop-in replacement for home_screen.dart
// //
// //  Performance wins vs original:
// //  1. No more full-screen Obx() wrapping everything — each zone
// //     (map, order card, bottom button) has its own tiny Obx()
// //  2. Surge fee + toPay read from controller Rx fields — zero
// //     FutureBuilder instances in the widget tree during rebuilds
// //  3. AnimatedSwitcher only where state actually changes (card ↔
// //     accept/reject ↔ empty) — prevents flash on minor updates
// //  4. buildOrderActionsCard totalAmount computed once in controller
// //  5. PiP overlay is a separate minimal widget, not a full card
// //  6. Bottom action button text driven by Obx on status Rx alone
// // ============================================================
//
// import 'dart:async';
// import 'package:android_pip/android_pip.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart' as flutterMap;
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:latlong2/latlong.dart' as latlng;
// import 'package:provider/provider.dart';
// import 'package:timelines_plus/timelines_plus.dart';
//
// import 'package:jippydriver_driver/app/chat_screens/chat_screen.dart';
// import 'package:jippydriver_driver/app/home_screen/screens/delivery_order_screen/deliver_order_screen.dart';
// import 'package:jippydriver_driver/app/home_screen/screens/pickup_order_screen/pickup_order_screen.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
// import 'package:jippydriver_driver/controllers/dash_board_controller.dart';
// import 'package:jippydriver_driver/app/home_screen/controller/home_controller.dart';
// import 'package:jippydriver_driver/app/home_screen/widgets/order_bottom_drawer.dart';
// import 'package:jippydriver_driver/app/home_screen/widgets/today_dashboard_section.dart';
// import 'package:jippydriver_driver/main.dart';       // isInPipMode
// import 'package:jippydriver_driver/models/order_model.dart';
//
// import 'package:jippydriver_driver/services/http_client_service.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:jippydriver_driver/themes/responsive.dart';
// import 'package:jippydriver_driver/themes/round_button_fill.dart';
// import 'package:jippydriver_driver/utils/app_logger.dart';
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// import 'package:jippydriver_driver/utils/fire_store_utils.dart';
// import 'package:jippydriver_driver/utils/utils.dart';
// import 'package:jippydriver_driver/widget/my_separator.dart';
//
// // ---------------------------------------------------------------------------
// //  HomeScreen
// // ---------------------------------------------------------------------------
// class HomeScreen extends StatefulWidget {
//   final bool? isAppBarShow;
//   const HomeScreen({super.key, this.isAppBarShow});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
//
//   Timer? _pipDelayTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     _pipDelayTimer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final ctrl = Get.find<HomeController>();
//     ctrl.updateAppLifecycleState(state);
//
//     if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
//         ModalRoute.of(context)?.isCurrent == true) {
//       final hasOrder = ctrl.currentOrder.value.id != null &&
//           ctrl.currentOrder.value.driverID == Constant.userModel?.id;
//       if (hasOrder) {
//         _pipDelayTimer?.cancel();
//         _pipDelayTimer = Timer(const Duration(seconds: 1), () {
//           if (mounted) _enterPip();
//         });
//       } else {
//         isInPipMode.value = false;
//       }
//     } else if (state == AppLifecycleState.resumed &&
//         ModalRoute.of(context)?.isCurrent == true) {
//       _pipDelayTimer?.cancel();
//       isInPipMode.value = false;
//       ctrl.forceRefreshOrders();
//     } else {
//       _pipDelayTimer?.cancel();
//       isInPipMode.value = false;
//     }
//   }
//
//   Future<void> _enterPip() async {
//     if (isInPipMode.value) return;
//     try {
//       await AndroidPIP().enterPipMode(aspectRatio: [1, 1]);
//       await Future.delayed(const Duration(milliseconds: 300));
//       if (mounted) isInPipMode.value = true;
//     } catch (_) {
//       isInPipMode.value = false;
//     }
//   }
//
//   // ══════════════════════════════════════════════════════════════════════
//   //  Build
//   // ══════════════════════════════════════════════════════════════════════
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Provider.of<DarkThemeProvider>(context);
//     return GetX<HomeController>(
//       init: HomeController(),
//       builder: (ctrl) => Scaffold(
//         appBar: widget.isAppBarShow == true ? _buildAppBar(theme) : null,
//         bottomSheet: Obx(() {
//           final showDrawer = _shouldShowBottomDrawer(ctrl);
//           return OrderBottomDrawer(
//             visible: showDrawer,
//             child: showDrawer
//                 ? _buildBottomZone(theme, ctrl)
//                 : const SizedBox.shrink(),
//           );
//         }),
//         body: ctrl.isLoading.value
//             ? Constant.loader()
//             : _buildBody(theme, ctrl),
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar(DarkThemeProvider theme) => AppBar(
//     backgroundColor: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
//     centerTitle: false,
//     iconTheme: const IconThemeData(color: AppThemeData.grey900, size: 20),
//     title: Text('Order'.tr,
//         style: TextStyle(
//           color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//           fontSize: 18,
//           fontFamily: AppThemeData.medium,
//         )),
//   );
//
//   Widget _buildBody(DarkThemeProvider theme, HomeController ctrl) {
//     // Document verification pending
//     if (Constant.userModel?.vendorID?.isEmpty == true &&
//         Constant.isDriverVerification == true &&
//         Constant.userModel?.isDocumentVerify == false) {
//       return _buildVerificationPending(theme);
//     }
//
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(12, 10, 12, 220),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       // Low-balance warning
//       if (Constant.userModel?.vendorID?.isEmpty == true &&
//           double.parse(Constant.userModel!.walletAmount?.toString() ?? '0') <
//               double.parse(Constant.minimumDepositToRideAccept))
//         // Padding(
//         //   padding: const EdgeInsets.all(8),
//         //   child: Text(
//         //     '${'Please Contact your fleet manager your balance reached'.tr} ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept)}',
//         //     textAlign: TextAlign.center,
//         //     style: TextStyle(
//         //       color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//         //       fontSize: 14,
//         //       fontFamily: AppThemeData.semiBold,
//         //     ),
//         //   ),
//         // ),
//       TodayDashboardSection(theme: theme, ctrl: ctrl),
//     ]));
//   }
//
//   bool _shouldShowBottomDrawer(HomeController ctrl) {
//     if (isInPipMode.value) return false;
//     final order = ctrl.currentOrder.value;
//     final driver = ctrl.driverModel.value;
//     final isInRequestData = driver.orderRequestData?.contains(order.id) ?? false;
//     final hasNoDriver = order.driverID == null || order.driverID!.isEmpty;
//     final shouldShowAcceptReject = order.id != null &&
//         (isInRequestData ||
//             order.status == Constant.driverPending ||
//             (order.status == Constant.orderAccepted && hasNoDriver)) &&
//         hasNoDriver &&
//         order.address != null &&
//         (order.vendor != null || (order.vendorID?.isNotEmpty ?? false));
//     final shouldShowOrderCard = order.id != null &&
//         order.driverID == Constant.userModel?.id &&
//         (!isInRequestData || order.status == Constant.driverPending);
//     return shouldShowAcceptReject || shouldShowOrderCard;
//   }
//
//   // ══════════════════════════════════════════════════════════════════════
//   //  Map widget (only rebuilds when markers / polylines Rx change)
//   // ══════════════════════════════════════════════════════════════════════
//
//   Widget _buildMap(DarkThemeProvider theme, HomeController ctrl) {
//     if (Constant.mapType != 'inappmap') return _buildExternalMapPlaceholder(theme, ctrl);
//     if (Constant.selectedMapType == 'osm') return _buildOSMMap(ctrl);
//     return _buildGoogleMap(ctrl);
//   }
//
//   Widget _buildGoogleMap(HomeController ctrl) {
//     // Observe markers and polylines separately so only this widget rebuilds
//     return Obx(() => GoogleMap(
//       onMapCreated: (c) async {
//         ctrl.mapController = c;
//         await Future.delayed(const Duration(milliseconds: 300));
//         if (!ctrl.hasInitialCameraSet) {
//           final loc = ctrl.driverModel.value.location;
//           if (loc?.latitude != null) {
//             ctrl.mapController!.animateCamera(CameraUpdate.newCameraPosition(
//               CameraPosition(target: LatLng(loc!.latitude!, loc.longitude!), zoom: 15),
//             ));
//             ctrl.hasInitialCameraSet = true;
//           }
//         }
//       },
//       myLocationEnabled: !(ctrl.currentOrder.value.id != null &&
//           ctrl.currentOrder.value.status == Constant.driverPending),
//       myLocationButtonEnabled: true,
//       mapType: MapType.normal,
//       zoomControlsEnabled: true,
//       compassEnabled: true,
//       tiltGesturesEnabled: true,
//       rotateGesturesEnabled: true,
//       // These are reactive — only this widget rebuilds when they change
//       polylines: Set<Polyline>.of(ctrl.polyLines.values),
//       markers: ctrl.markers.values.toSet(),
//       initialCameraPosition: CameraPosition(
//         zoom: 15,
//         target: LatLng(
//           ctrl.driverModel.value.location?.latitude ?? 0.0,
//           ctrl.driverModel.value.location?.longitude ?? 0.0,
//         ),
//       ),
//     ));
//   }
//
//   Widget _buildOSMMap(HomeController ctrl) {
//     return Obx(() => flutterMap.FlutterMap(
//       mapController: ctrl.osmMapController,
//       options: flutterMap.MapOptions(
//         initialCenter: latlng.LatLng(
//           ctrl.driverModel.value.location?.latitude ?? 0.0,
//           ctrl.driverModel.value.location?.longitude ?? 0.0,
//         ),
//         initialZoom: 12,
//         onMapReady: () => ctrl.setOsmMapReady(true),
//       ),
//       children: [
//         flutterMap.TileLayer(
//           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//           userAgentPackageName: 'com.example.app',
//         ),
//         flutterMap.MarkerLayer(
//           markers: ctrl.currentOrder.value.id == null ? [] : ctrl.osmMarkers,
//         ),
//         if (ctrl.routePoints.isNotEmpty && ctrl.currentOrder.value.id != null)
//           flutterMap.PolylineLayer(polylines: [
//             flutterMap.Polyline(
//               points: ctrl.routePoints,
//               strokeWidth: 7.0,
//               color: AppThemeData.secondary300,
//             ),
//           ]),
//       ],
//     ));
//   }
//
//   // ══════════════════════════════════════════════════════════════════════
//   //  Bottom zone — switches between accept/reject, order card, and empty
//   // ══════════════════════════════════════════════════════════════════════
//
//   Widget _buildBottomZone(DarkThemeProvider theme, HomeController ctrl) {
//     // PiP mode → minimal overlay only
//     if (isInPipMode.value) {
//       return _PipOverlay(ctrl: ctrl, theme: theme);
//     }
//
//     final order = ctrl.currentOrder.value;
//     final driver = ctrl.driverModel.value;
//
//     final isInRequestData = driver.orderRequestData?.contains(order.id) ?? false;
//     final hasNoDriver = order.driverID == null || order.driverID!.isEmpty;
//
//     final shouldShowAcceptReject = order.id != null &&
//         (isInRequestData ||
//             order.status == Constant.driverPending ||
//             (order.status == Constant.orderAccepted && hasNoDriver)) &&
//         hasNoDriver &&
//         order.address != null &&
//         (order.vendor != null || (order.vendorID?.isNotEmpty ?? false));
//
//     final shouldShowOrderCard = order.id != null &&
//         order.driverID == Constant.userModel?.id &&
//         (!isInRequestData || order.status == Constant.driverPending);
//
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 250),
//       switchInCurve: Curves.easeOut,
//       switchOutCurve: Curves.easeIn,
//       transitionBuilder: (child, anim) => SlideTransition(
//         position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
//             .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
//         child: FadeTransition(opacity: anim, child: child),
//       ),
//       child: shouldShowAcceptReject
//           ? KeyedSubtree(
//         key: const ValueKey('accept_reject'),
//         child: _AcceptRejectCard(ctrl: ctrl, theme: theme),
//       )
//           : shouldShowOrderCard
//           ? KeyedSubtree(
//         key: const ValueKey('order_card'),
//         child: _OrderActionsCard(ctrl: ctrl, theme: theme),
//       )
//           : KeyedSubtree(
//         key: const ValueKey('no_order'),
//         child: const SizedBox.shrink(),
//       ),
//     );
//   }
//
//   // ══════════════════════════════════════════════════════════════════════
//   //  Verification pending
//   // ══════════════════════════════════════════════════════════════════════
//
//   Widget _buildVerificationPending(DarkThemeProvider theme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             decoration: ShapeDecoration(
//               color: theme.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: SvgPicture.asset('assets/icons/ic_document.svg'),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text('Document Verification in Pending'.tr,
//               style: TextStyle(
//                 color: theme.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
//                 fontSize: 22,
//                 fontFamily: AppThemeData.semiBold,
//               )),
//           const SizedBox(height: 5),
//           Text(
//             'Your documents are being reviewed. We will notify you once the verification is complete.'.tr,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey500,
//               fontSize: 16,
//               fontFamily: AppThemeData.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           RoundedButtonFill(
//             title: 'View Status'.tr,
//             width: 55, height: 5.5,
//             color: AppThemeData.secondary300,
//             textColor: AppThemeData.grey50,
//             onPress: () {
//               DashBoardController dashCtrl = Get.put(DashBoardController());
//               dashCtrl.drawerIndex.value = 3;
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildExternalMapPlaceholder(DarkThemeProvider theme, HomeController ctrl) {
//     final name = _mapName();
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SvgPicture.asset('assets/images/ic_location_map.svg'),
//           const SizedBox(height: 10),
//           Text('${'Navigate with'.tr} $name',
//               style: TextStyle(
//                 color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//                 fontSize: 22,
//                 fontFamily: AppThemeData.semiBold,
//               )),
//           const SizedBox(height: 30),
//           RoundedButtonFill(
//             title: 'Redirect $name'.tr,
//             width: 55, height: 5.5,
//             color: AppThemeData.driverApp300,
//             textColor: AppThemeData.grey50,
//             onPress: () => _handleExternalMapRedirect(ctrl),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _mapName() => switch (Constant.mapType) {
//     'google'      => 'Google Map',
//     'googleGo'    => 'Google Go',
//     'waze'        => 'Waze Map',
//     'mapswithme'  => 'MapsWithMe',
//     'yandexNavi'  => 'Yandex Navi',
//     'yandexMaps'  => 'Yandex Maps',
//     _             => '',
//   };
//
//   void _handleExternalMapRedirect(HomeController ctrl) {
//     final order = ctrl.currentOrder.value;
//     if (order.id == null) return;
//     if (order.status == Constant.orderShipped) {
//       Utils.redirectMap(
//         name: order.vendor!.title.toString(),
//         latitude: order.vendor!.latitude ?? 0.0,
//         longLatitude: order.vendor!.longitude ?? 0.0,
//       );
//     } else if (order.status == Constant.orderInTransit) {
//       Utils.redirectMap(
//         name: order.author!.firstName.toString(),
//         latitude: order.address!.location!.latitude ?? 0.0,
//         longLatitude: order.address!.location!.longitude ?? 0.0,
//       );
//     }
//   }
// }
//
// // ===========================================================================
// //  Accept / Reject card — extracted as separate StatelessWidget so it is NOT
// //  rebuilt when other parts of HomeScreen change.
// // ===========================================================================
// class _AcceptRejectCard extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   const _AcceptRejectCard({required this.ctrl, required this.theme});
//
//   @override
//   Widget build(BuildContext context) {
//     final vendor  = ctrl.currentOrder.value.vendor;
//     final address = ctrl.currentOrder.value.address;
//     double km = 0.0;
//     if (vendor != null && address?.location != null) {
//       km = Geolocator.distanceBetween(
//         vendor.latitude ?? 0.0, vendor.longitude ?? 0.0,
//         address!.location!.latitude ?? 0.0, address.location!.longitude ?? 0.0,
//       ) / 1000;
//     }
//
//     return Padding(
//       padding: const EdgeInsets.all(8),
//       child: Container(
//         decoration: ShapeDecoration(
//           color: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildTimeline(vendor, address),
//               MySeparator(
//                 color: theme.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
//               ),
//               const SizedBox(height: 8),
//
//               // ── Reactive charge rows — reads from Rx, no FutureBuilder ──
//               _ChargeBreakdown(ctrl: ctrl, theme: theme, km: km),
//
//               const SizedBox(height: 10),
//
//               // ── Action buttons ─────────────────────────────────────────
//               SafeArea(
//                 child: Row(children: [
//                   Expanded(
//                     child: RoundedButtonFill(
//                       title: 'Reject'.tr,
//                       width: 24, height: 5.5,
//                       borderRadius: 10,
//                       color: AppThemeData.danger300,
//                       textColor: AppThemeData.grey50,
//                       onPress: () {
//                         AppLogger.log('Reject tapped', tag: 'UserAction');
//                         ctrl.rejectOrder();
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: RoundedButtonFill(
//                       title: 'Accept'.tr,
//                       width: 24, height: 5.5,
//                       borderRadius: 10,
//                       color: AppThemeData.success400,
//                       textColor: AppThemeData.grey50,
//                       onPress: () async {
//                         AppLogger.log('Accept tapped', tag: 'UserAction');
//                         await ctrl.acceptOrder();
//                       },
//                     ),
//                   ),
//                 ]),
//               ),
//               const SizedBox(height: 6),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimeline(vendor, address) {
//     return Timeline.tileBuilder(
//       shrinkWrap: true,
//       padding: EdgeInsets.zero,
//       physics: const NeverScrollableScrollPhysics(),
//       theme: TimelineThemeData(nodePosition: 0),
//       builder: TimelineTileBuilder.connected(
//         contentsAlign: ContentsAlign.basic,
//         indicatorBuilder: (_, index) => index == 0
//             ? _circleIcon('assets/icons/ic_building.svg', AppThemeData.primary50, AppThemeData.primary300)
//             : _circleIcon('assets/icons/ic_location.svg', AppThemeData.driverApp50, AppThemeData.driverApp300),
//         connectorBuilder: (_, __, ___) =>
//         const DashedLineConnector(color: AppThemeData.grey300, gap: 3),
//         contentsBuilder: (ctx, index) => Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: index == 0
//                 ? [
//               Text('${vendor?.title ?? 'N/A'}',
//                   style: _titleStyle()),
//               Text('${vendor?.location ?? 'N/A'}',
//                   style: _subtitleStyle()),
//             ]
//                 : [
//               Text('Deliver to the'.tr, style: _titleStyle()),
//               Text(address?.getFullAddress() ?? 'N/A',
//                   style: _subtitleStyle()),
//             ],
//           ),
//         ),
//         itemCount: 2,
//       ),
//     );
//   }
//
//   Widget _circleIcon(String asset, Color bg, Color iconColor) => Container(
//     decoration: ShapeDecoration(
//       color: bg,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
//     ),
//     child: Padding(
//       padding: const EdgeInsets.all(10),
//       child: SvgPicture.asset(asset,
//           colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
//     ),
//   );
//
//   TextStyle _titleStyle() => TextStyle(
//     fontFamily: AppThemeData.semiBold,
//     fontSize: 16,
//     color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//   );
//
//   TextStyle _subtitleStyle() => TextStyle(
//     fontFamily: AppThemeData.medium,
//     fontSize: 14,
//     color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//   );
// }
//
// // ---------------------------------------------------------------------------
// //  Charge breakdown — reads Rx fields, zero extra API calls on rebuild
// // ---------------------------------------------------------------------------
// class _ChargeBreakdown extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   final double km;
//   const _ChargeBreakdown({required this.ctrl, required this.theme, required this.km});
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final tip = double.tryParse(ctrl.currentOrder.value.tipAmount?.toString() ?? '0') ?? 0.0;
//       final surge = ctrl.surgeFee.value;
//       final hasSurge = surge > 0;
//
//       // Same rupee totals as [HomeController] / Firestore (₹3/km pickup; ≤4km@₹8/km; >4km → ₹32 + ceil(extra km)×₹10).
//       final driverToRestaurantCharge = ctrl.driverToRestaurantCharge.value;
//       final restaurantToCustomerCharge = ctrl.restaurantToCustomerCharge.value;
//
//       final deliveryChargeTotal = driverToRestaurantCharge + restaurantToCustomerCharge;
//       final total = deliveryChargeTotal + tip + surge;
//       final isVendorDriver = ctrl.driverModel.value.vendorID?.isEmpty == true;
//
//       return Column(children: [
//         // Distance row
//         _row(
//           label: 'Trip Distance'.tr,
//           value: '${km.toStringAsFixed(2)} ${Constant.distanceType}',
//         ),
//
//         // Tips row (only when > 0)
//         if (tip > 0)
//           _row(
//             label: 'Tips'.tr,
//             value: Constant.amountShow(amount: tip.toString()),
//           ),
//         const SizedBox(height: 8),
//
//         // Delivery charge breakdown
//         if (isVendorDriver)
//           _row(
//             label: 'Delivery Charge'.tr,
//             value: '${driverToRestaurantCharge.toStringAsFixed(2)} + '
//                 '${restaurantToCustomerCharge.toStringAsFixed(2)} = '
//                 '${deliveryChargeTotal.toStringAsFixed(2)}',
//           ),
//
//         // Surge fee
//         if (hasSurge) _surgeRow(surge),
//
//         const SizedBox(height: 8),
//
//         // Total earnings box
//         _totalEarningsBox(total),
//       ]);
//     });
//   }
//
//   Widget _row({required String label, required String value}) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 3),
//     child: Row(children: [
//       Expanded(child: Text(label,
//           style: TextStyle(
//             fontFamily: AppThemeData.regular,
//             color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//             fontSize: 16,
//           ))),
//       Text(value,
//           style: TextStyle(
//             fontFamily: AppThemeData.semiBold,
//             color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//             fontSize: 16,
//           )),
//     ]),
//   );
//
//   Widget _surgeRow(double surge) => Container(
//     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//     decoration: BoxDecoration(
//       color: AppThemeData.success50.withOpacity(0.3),
//       borderRadius: BorderRadius.circular(6),
//     ),
//     child: Row(children: [
//       Expanded(child: Row(children: [
//         Text('Surge Fee'.tr,
//             style: TextStyle(
//               fontFamily: AppThemeData.regular,
//               color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//               fontSize: 16,
//             )),
//         const SizedBox(width: 6),
//         const Icon(Icons.trending_up_rounded, color: AppThemeData.success400, size: 16),
//       ])),
//       Text('+${surge.toStringAsFixed(2)}',
//           style: const TextStyle(
//             fontFamily: AppThemeData.semiBold,
//             color: AppThemeData.success500,
//             fontSize: 17,
//           )),
//     ]),
//   );
//
//   Widget _totalEarningsBox(double total) => Container(
//     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//     decoration: BoxDecoration(
//       color: AppThemeData.primary50.withOpacity(0.2),
//       borderRadius: BorderRadius.circular(10),
//       border: Border.all(color: AppThemeData.primary200),
//     ),
//     child: Row(children: [
//       Expanded(child: Text('Total Earnings'.tr,
//           style: TextStyle(
//             fontFamily: AppThemeData.semiBold,
//             color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//             fontSize: 16,
//           ))),
//       Text(total.toInt().toString(),
//           style: const TextStyle(
//             fontFamily: AppThemeData.bold,
//             color: AppThemeData.primary500,
//             fontSize: 20,
//           )),
//     ]),
//   );
// }
//
// // ===========================================================================
// //  Order actions card (shown for active / in-progress orders)
// // ===========================================================================
// class _OrderActionsCard extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   const _OrderActionsCard({required this.ctrl, required this.theme});
//
//   @override
//   Widget build(BuildContext context) {
//     final order = ctrl.currentOrder.value;
//
//     double subTotal = 0.0;
//     for (final p in order.products ?? []) {
//       final price = double.tryParse(p.discountPrice?.toString() ?? '0') ?? 0.0;
//       final qty   = double.tryParse(p.quantity?.toString() ?? '1') ?? 1.0;
//       final extra = double.tryParse(p.extrasPrice?.toString() ?? '0') ?? 0.0;
//       subTotal += (price <= 0
//           ? (double.tryParse(p.price?.toString() ?? '0') ?? 0.0)
//           : price) * qty + extra * qty;
//     }
//
//     return Container(
//       color: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         // Collapse handle
//         GestureDetector(
//           onTap: ctrl.changeArrow,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 4),
//             child: Icon(
//               ctrl.arrowDrop.value
//                   ? Icons.keyboard_arrow_up_rounded
//                   : Icons.keyboard_arrow_down_rounded,
//               color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//             ),
//           ),
//         ),
//
//         // Content (collapsed or expanded)
//         Obx(() => AnimatedCrossFade(
//           duration: const Duration(milliseconds: 250),
//           crossFadeState: ctrl.arrowDrop.value
//               ? CrossFadeState.showSecond
//               : CrossFadeState.showFirst,
//           firstChild: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: _OrderCardContent(ctrl: ctrl, theme: theme, order: order),
//           ),
//           secondChild: const SizedBox.shrink(),
//         )),
//
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
//           child: _NavigationSection(ctrl: ctrl, theme: theme, order: order),
//         ),
//
//         // Rebuilt by parent bottom-zone Obx when order status changes.
//         _ActionButton(ctrl: ctrl, theme: theme, order: order),
//       ]),
//     );
//   }
// }
//
// // ---------------------------------------------------------------------------
// class _OrderCardContent extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   final OrderModel order;
//   const _OrderCardContent({required this.ctrl, required this.theme, required this.order});
//
//   @override
//   Widget build(BuildContext context) {
//     final isPickupStage = order.status == Constant.orderShipped ||
//         order.status == Constant.driverAccepted;
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (isPickupStage) _buildPickupRow() else _buildDeliveryTimeline(),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           child: MySeparator(
//             color: theme.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
//           ),
//         ),
//         _paymentSection(),
//         const SizedBox(height: 4),
//       ],
//     );
//   }
//
//   Widget _buildPickupRow() => Row(children: [
//     Container(
//       decoration: ShapeDecoration(
//         color: AppThemeData.primary50,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(10),
//         child: SvgPicture.asset('assets/icons/ic_building.svg',
//             colorFilter: const ColorFilter.mode(AppThemeData.primary300, BlendMode.srcIn)),
//       ),
//     ),
//     const SizedBox(width: 10),
//     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text('${order.vendor?.title}',
//           style: TextStyle(
//             fontFamily: AppThemeData.semiBold, fontSize: 16,
//             color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//           )),
//       Text('${order.vendor?.location}',
//           style: TextStyle(
//             fontFamily: AppThemeData.medium, fontSize: 14,
//             color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//           )),
//     ])),
//     const SizedBox(width: 10),
//     _phoneButton(() => Constant.makePhoneCall(order.vendor!.phonenumber.toString())),
//   ]);
//
//   Widget _buildDeliveryTimeline() => Timeline.tileBuilder(
//     shrinkWrap: true, padding: EdgeInsets.zero,
//     physics: const NeverScrollableScrollPhysics(),
//     theme: TimelineThemeData(nodePosition: 0),
//     builder: TimelineTileBuilder.connected(
//       contentsAlign: ContentsAlign.basic,
//       indicatorBuilder: (_, index) => index == 0
//           ? _circleIcon('assets/icons/ic_building.svg', AppThemeData.primary50, AppThemeData.primary300)
//           : _circleIcon('assets/icons/ic_location.svg', AppThemeData.driverApp50, AppThemeData.driverApp300),
//       connectorBuilder: (_, __, ___) => const DashedLineConnector(color: AppThemeData.grey300, gap: 3),
//       contentsBuilder: (ctx, index) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//         child: index == 0
//             ? Row(children: [
//           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text('${order.vendor?.title}', style: _titleStyle()),
//             Text('${order.vendor?.location}', style: _subtitleStyle()),
//           ])),
//           _phoneButton(() => Constant.makePhoneCall(order.vendor!.phonenumber.toString())),
//         ])
//             : Row(children: [
//           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text('Deliver to the'.tr, style: _titleStyle()),
//             Text(order.address!.getFullAddress(), style: _subtitleStyle()),
//           ])),
//           _phoneButton(() async {
//             ShowToastDialog.showLoader('Please wait'.tr);
//             final customer = await FireStoreUtils.getUserProfile(order.authorID.toString());
//             ShowToastDialog.closeLoader();
//             if (customer?.phoneNumber != null) Constant.makePhoneCall(customer!.phoneNumber!);
//           }),
//           const SizedBox(width: 8),
//           _chatButton(ctx),
//         ]),
//       ),
//       itemCount: 2,
//     ),
//   );
//
//   Widget _chatButton(BuildContext ctx) => InkWell(
//     onTap: () async {
//       ShowToastDialog.showLoader('Please wait'.tr);
//       final customer = await FireStoreUtils.getUserProfile(order.authorID.toString());
//       final driver   = await FireStoreUtils.getUserProfile(order.driverID.toString());
//       ShowToastDialog.closeLoader();
//       // Get.to(const ChatScreen(), arguments: {
//       //   'customerName': customer?.fullName() ?? '',
//       //   'restaurantName': driver?.fullName() ?? '',
//       //   'orderId': order.id,
//       //   'restaurantId': driver?.id,
//       //   'customerId': customer?.id,
//       //   'customerProfileImage': customer?.profilePictureURL ?? '',
//       //   'restaurantProfileImage': driver?.profilePictureURL ?? '',
//       //   'token': customer?.fcmToken,
//       //   'chatType': 'Driver',
//       // });
//     },
//     child: _iconCircle(child: SvgPicture.asset('assets/icons/ic_wechat.svg')),
//   );
//
//   Widget _paymentSection() => Column(children: [
//     _payRow('Payment Type'.tr,
//         order.paymentMethod?.toLowerCase() == 'cod' ? 'Cash on delivery' : 'Online'),
//     if (order.paymentMethod?.toLowerCase() == 'cod') ...[
//       const SizedBox(height: 4),
//       // Reads Rx — no FutureBuilder, no extra HTTP call on rebuild
//       Obx(() => _payRow('Collect Payment from customer'.tr,
//           Constant.amountShow(amount: ctrl.toPayAmount.value.toString()))),
//     ],
//   ]);
//
//   Widget _payRow(String label, String value) => Row(children: [
//     Expanded(child: Text(label,
//         style: TextStyle(
//           fontFamily: AppThemeData.regular,
//           color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//           fontSize: 16,
//         ))),
//     Flexible(
//       child: Text(
//         value,
//         textAlign: TextAlign.end,
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//         style: TextStyle(
//           fontFamily: AppThemeData.semiBold,
//           color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//           fontSize: 16,
//         ),
//       ),
//     ),
//   ]);
//
//   Widget _phoneButton(VoidCallback onTap) => InkWell(
//     onTap: onTap,
//     child: _iconCircle(child: SvgPicture.asset('assets/icons/ic_phone_call.svg')),
//   );
//
//   Widget _iconCircle({required Widget child}) => Container(
//     width: 42, height: 42,
//     decoration: ShapeDecoration(
//       shape: RoundedRectangleBorder(
//         side: BorderSide(
//           width: 1,
//           color: theme.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
//         ),
//         borderRadius: BorderRadius.circular(120),
//       ),
//     ),
//     child: Padding(padding: const EdgeInsets.all(9), child: child),
//   );
//
//   Widget _circleIcon(String asset, Color bg, Color ic) => Container(
//     decoration: ShapeDecoration(
//       color: bg,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
//     ),
//     child: Padding(
//       padding: const EdgeInsets.all(10),
//       child: SvgPicture.asset(asset, colorFilter: ColorFilter.mode(ic, BlendMode.srcIn)),
//     ),
//   );
//
//   TextStyle _titleStyle() => TextStyle(
//     fontFamily: AppThemeData.semiBold, fontSize: 16,
//     color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//   );
//   TextStyle _subtitleStyle() => TextStyle(
//     fontFamily: AppThemeData.medium, fontSize: 14,
//     color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//   );
// }
//
// // ---------------------------------------------------------------------------
// //  Bottom action button — only rebuilt when currentOrder.status changes
// // ---------------------------------------------------------------------------
// class _ActionButton extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   final OrderModel order;
//   const _ActionButton({required this.ctrl, required this.theme, required this.order});
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () => _handleTap(context),
//       child: SafeArea(
//         child: Container(
//           color: AppThemeData.driverApp300,
//           width: Responsive.width(100, context),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             child: Text(
//               _buttonLabel(),
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey900,
//                 fontSize: 16,
//                 fontFamily: AppThemeData.semiBold,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _buttonLabel() {
//     final status = order.status ?? '';
//     final isDirectDelivery = ctrl.driverModel.value.vendorID?.isEmpty == true;
//     if (status == Constant.orderShipped || status == Constant.driverAccepted) {
//       return 'Reached restaurant for Pickup'.tr;
//     }
//     if (status == Constant.orderInTransit) {
//       return isDirectDelivery
//           ? 'Reached the Customers Door Steps'.tr
//           : 'Order Delivered'.tr;
//     }
//     if (status == Constant.driverPending) return 'Reached restaurant for Pickup'.tr;
//     return 'Order Delivered'.tr;
//   }
//
//   Future<void> _handleTap(BuildContext context) async {
//     final status = order.status ?? '';
//     if (status == Constant.orderShipped || status == Constant.driverAccepted) {
//       final result = await Get.to(const PickupOrderScreen(),
//           arguments: {'orderModel': order});
//       if (result == true) {
//         // Optimistic status update
//         final cached = ctrl.currentOrder.value;
//         cached.status = Constant.orderInTransit;
//         ctrl.currentOrder.value = cached;
//         ctrl.currentOrder.refresh();
//         await Future.delayed(const Duration(milliseconds: 800));
//         await ctrl.refreshCurrentOrder(forceRefresh: true);
//       }
//     } else {
//       final result = await Get.to(const DeliverOrderScreen(),
//           arguments: {'orderModel': order});
//       if (result == true || result is String) {
//         final completedId = (result is String ? result : null) ?? order.id?.toString();
//         if (completedId != null) {
//           ctrl.markOrderAsCompleted(completedId);
//           ctrl.driverModel.value.inProgressOrderID
//               ?.removeWhere((id) => id?.toString() == completedId);
//           ctrl.driverModel.value.orderRequestData
//               ?.removeWhere((id) => id?.toString() == completedId);
//           final h = HttpClientService();
//           await h.invalidateCache('orders/$completedId');
//         }
//         await FireStoreUtils.updateUser(ctrl.driverModel.value);
//         ctrl.currentOrder.value = OrderModel();
//         await ctrl.clearMap();
//         ctrl.resetStatusTracking();
//         ctrl.update();
//         if (Constant.singleOrderReceive == false) Get.back();
//       }
//     }
//   }
// }
//
// class _NavigationSection extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   final OrderModel order;
//
//   const _NavigationSection({
//     required this.ctrl,
//     required this.theme,
//     required this.order,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final status = ctrl.currentOrder.value.status ?? '';
//       final isPickupState = ctrl.isPickupNavigationState;
//       final isDropState = ctrl.isDropNavigationState;
//
//       if (!isPickupState && !isDropState) return const SizedBox.shrink();
//
//       final pickupText = order.vendor?.location ?? 'N/A';
//       final dropText = order.address?.getFullAddress() ?? 'N/A';
//       final buttonLabel =
//           isPickupState ? 'Navigate to Restaurant'.tr : 'Navigate to Customer'.tr;
//
//       final hasDestination = isPickupState
//           ? (order.vendor?.latitude != null && order.vendor?.longitude != null)
//           : (order.address?.location?.latitude != null &&
//               order.address?.location?.longitude != null);
//       final canNavigate = hasDestination;
//
//       return Container(
//         decoration: BoxDecoration(
//           color: theme.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _infoRow('Pickup Location'.tr, pickupText),
//               const SizedBox(height: 6),
//               _infoRow('Drop Location'.tr, dropText),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   Expanded(
//                     child: RoundedButtonFill(
//                       title: ctrl.isNavigatingToMap.value
//                           ? 'Opening Maps...'.tr
//                           : buttonLabel,
//                       width: 40,
//                       height: 5,
//                       borderRadius: 10,
//                       color: canNavigate
//                           ? AppThemeData.primary500
//                           : AppThemeData.grey400,
//                       textColor: AppThemeData.grey50,
//                       onPress: (!canNavigate || ctrl.isNavigatingToMap.value)
//                           ? null
//                           : () async => ctrl.openCurrentOrderNavigation(),
//                     ),
//                   ),
//                   // const SizedBox(width: 8),
//                   // _callAction(
//                   //   icon: Icons.storefront_outlined,
//                   //   onTap: () {
//                   //     final phone = order.vendor?.phonenumber?.toString() ?? '';
//                   //     if (phone.isEmpty) return;
//                   //     Constant.makePhoneCall(phone);
//                   //   },
//                   // ),
//                   // const SizedBox(width: 6),
//                   // _callAction(
//                   //   icon: Icons.person_outline_rounded,
//                   //   onTap: () {
//                   //     final phone = order.author?.phoneNumber?.toString() ?? '';
//                   //     if (phone.isEmpty) return;
//                   //     Constant.makePhoneCall(phone);
//                   //   },
//                   // ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     });
//   }
//
//   Widget _infoRow(String title, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           width: 100,
//           child: Text(
//             title,
//             style: TextStyle(
//               fontFamily: AppThemeData.medium,
//               fontSize: 12,
//               color: theme.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
//             ),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             value,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontFamily: AppThemeData.semiBold,
//               fontSize: 13,
//               color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _callAction({required IconData icon, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: AppThemeData.grey50,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: AppThemeData.grey300),
//         ),
//         child: Icon(icon, size: 20, color: AppThemeData.grey800),
//       ),
//     );
//   }
// }
//
// // ===========================================================================
// //  PiP overlay — shown when app is in picture-in-picture mode.
// //  Kept minimal: only the essential status text + earnings.
// // ===========================================================================
// class _PipOverlay extends StatelessWidget {
//   final HomeController ctrl;
//   final DarkThemeProvider theme;
//   const _PipOverlay({required this.ctrl, required this.theme});
//
//   @override
//   Widget build(BuildContext context) {
//     final order = ctrl.currentOrder.value;
//     if (order.id == null) return const SizedBox.shrink();
//
//     return Container(
//       color: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       child: Row(
//         children: [
//           const Icon(Icons.delivery_dining, size: 24, color: AppThemeData.secondary300),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               order.status ?? '',
//               style: TextStyle(
//                 color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//                 fontSize: 14,
//                 fontFamily: AppThemeData.semiBold,
//               ),
//             ),
//           ),
//           Obx(() => Text(
//             ctrl.totalCalculatedCharge.value.toInt().toString(),
//             style: const TextStyle(
//               color: AppThemeData.primary500,
//               fontSize: 18,
//               fontFamily: AppThemeData.bold,
//             ),
//           )),
//         ],
//       ),
//     );
//   }
// }



import 'dart:async';
import 'package:android_pip/android_pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import 'package:jippydriver_driver/app/chat_screens/chat_screen.dart';
import 'package:jippydriver_driver/app/home_screen/screens/delivery_order_screen/deliver_order_screen.dart';
import 'package:jippydriver_driver/app/home_screen/screens/pickup_order_screen/pickup_order_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/dash_board_controller.dart';
import 'package:jippydriver_driver/app/home_screen/controller/home_controller.dart';
import 'package:jippydriver_driver/app/home_screen/widgets/order_bottom_drawer.dart';
import 'package:jippydriver_driver/app/home_screen/widgets/today_dashboard_section.dart';
import 'package:jippydriver_driver/main.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/services/http_client_service.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/themes/round_button_fill.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/utils.dart';
import 'package:jippydriver_driver/widget/my_separator.dart';

import '../../widget/expandable_address_text.dart';

// ---------------------------------------------------------------------------
//  HomeScreen
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final bool? isAppBarShow;
  const HomeScreen({super.key, this.isAppBarShow});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _pipDelayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pipDelayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = Get.find<HomeController>();
    ctrl.updateAppLifecycleState(state);

    if ((state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) &&
        ModalRoute.of(context)?.isCurrent == true) {
      final hasOrder = ctrl.currentOrder.value.id != null &&
          ctrl.currentOrder.value.driverID == Constant.userModel?.id;
      if (hasOrder) {
        _pipDelayTimer?.cancel();
        _pipDelayTimer =
            Timer(const Duration(seconds: 1), () {
              if (mounted) _enterPip();
            });
      } else {
        isInPipMode.value = false;
      }
    } else if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      _pipDelayTimer?.cancel();
      isInPipMode.value = false;
      ctrl.forceRefreshOrders();
    } else {
      _pipDelayTimer?.cancel();
      isInPipMode.value = false;
    }
  }

  Future<void> _enterPip() async {
    if (isInPipMode.value) return;
    try {
      await AndroidPIP().enterPipMode(aspectRatio: [1, 1]);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) isInPipMode.value = true;
    } catch (_) {
      isInPipMode.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DarkThemeProvider>(context);
    return GetX<HomeController>(
      init: HomeController(),
      builder: (ctrl) => Scaffold(
        backgroundColor:
        theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey100,
        appBar: widget.isAppBarShow == true ? _buildAppBar(theme) : null,
        // ── Bottom drawer (accept/reject or order card) ─────────────────
        bottomSheet: Obx(() {
          final show = _shouldShowDrawer(ctrl);
          return OrderBottomDrawer(
            visible: show,
            child: show
                ? _buildBottomZone(theme, ctrl)
                : const SizedBox.shrink(),
          );
        }),
        body: ctrl.isLoading.value
            ? Constant.loader()
            : _buildBody(theme, ctrl),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(DarkThemeProvider theme) => AppBar(
    backgroundColor:
    theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
    centerTitle: false,
    iconTheme:
    const IconThemeData(color: AppThemeData.grey900, size: 20),
    title: Text(
      'Order'.tr,
      style: TextStyle(
        color:
        theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
        fontSize: 18,
        fontFamily: AppThemeData.medium,
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  Body — THE BUG WAS HERE
  //  TodayDashboardSection was outside the Column children list.
  //  Fixed: it is now a proper child after the optional low-balance banner.
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(DarkThemeProvider theme, HomeController ctrl) {
    // Document-verification pending screen
    if (Constant.userModel?.vendorID?.isEmpty == true &&
        Constant.isDriverVerification == true &&
        Constant.userModel?.isDocumentVerify == false) {
      return _buildVerificationPending(theme);
    }

    final isLowBalance = Constant.userModel?.vendorID?.isEmpty == true &&
        double.parse(
            Constant.userModel!.walletAmount?.toString() ?? '0') <
            double.parse(Constant.minimumDepositToRideAccept);

    return RefreshIndicator(
      onRefresh: () => ctrl.forceRefreshOrders(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        // Extra bottom padding so content is never hidden behind the bottom drawer
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Optional low-balance warning ──────────────────────────────
            if (isLowBalance)
              _LowBalanceBanner(theme: theme),

            // ── TODAY DASHBOARD (was previously missing / broken) ─────────
            TodayDashboardSection(theme: theme, ctrl: ctrl),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Bottom-drawer visibility gate
  // ═══════════════════════════════════════════════════════════════════════

  bool _shouldShowDrawer(HomeController ctrl) {
    if (isInPipMode.value) return false;
    final order  = ctrl.currentOrder.value;
    final driver = ctrl.driverModel.value;

    final inReq      = driver.orderRequestData?.contains(order.id) ?? false;
    final noDriver   = order.driverID == null || order.driverID!.isEmpty;
    final acceptShow = order.id != null &&
        (inReq ||
            order.status == Constant.driverPending ||
            (order.status == Constant.orderAccepted && noDriver)) &&
        noDriver &&
        order.address != null &&
        (order.vendor != null || (order.vendorID?.isNotEmpty ?? false));

    final cardShow = order.id != null &&
        order.driverID == Constant.userModel?.id &&
        (!inReq || order.status == Constant.driverPending);

    return acceptShow || cardShow;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Bottom zone switcher
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBottomZone(DarkThemeProvider theme, HomeController ctrl) {
    if (isInPipMode.value) return _PipOverlay(ctrl: ctrl, theme: theme);

    final order  = ctrl.currentOrder.value;
    final driver = ctrl.driverModel.value;
    final inReq  = driver.orderRequestData?.contains(order.id) ?? false;
    final noDriver = order.driverID == null || order.driverID!.isEmpty;

    final showAcceptReject = order.id != null &&
        (inReq ||
            order.status == Constant.driverPending ||
            (order.status == Constant.orderAccepted && noDriver)) &&
        noDriver &&
        order.address != null &&
        (order.vendor != null || (order.vendorID?.isNotEmpty ?? false));

    final showCard = order.id != null &&
        order.driverID == Constant.userModel?.id &&
        (!inReq || order.status == Constant.driverPending);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => SlideTransition(
        position:
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: showAcceptReject
          ? KeyedSubtree(
        key: const ValueKey('accept_reject'),
        child: _AcceptRejectCard(ctrl: ctrl, theme: theme),
      )
          : showCard
          ? KeyedSubtree(
        key: const ValueKey('order_card'),
        child: _OrderActionsCard(ctrl: ctrl, theme: theme),
      )
          : const KeyedSubtree(
        key: ValueKey('no_order'),
        child: SizedBox.shrink(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Verification pending
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildVerificationPending(DarkThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: ShapeDecoration(
              color: theme.getThem()
                  ? AppThemeData.grey700
                  : AppThemeData.grey200,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(120)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SvgPicture.asset('assets/icons/ic_document.svg'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Document Verification in Pending'.tr,
            style: TextStyle(
              color: theme.getThem()
                  ? AppThemeData.grey100
                  : AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your documents are being reviewed. We will notify you once the verification is complete.'
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.getThem()
                  ? AppThemeData.grey50
                  : AppThemeData.grey500,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
          ),
          const SizedBox(height: 20),
          RoundedButtonFill(
            title: 'View Status'.tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.secondary300,
            textColor: AppThemeData.grey50,
            onPress: () {
              final dash = Get.put(DashBoardController());
              dash.drawerIndex.value = 3;
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Low-balance banner (extracted widget — prevents unnecessary rebuilds)
// ─────────────────────────────────────────────────────────────────────────────
class _LowBalanceBanner extends StatelessWidget {
  final DarkThemeProvider theme;
  const _LowBalanceBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppThemeData.danger50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppThemeData.danger200, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppThemeData.danger500, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${'Please Contact your fleet manager your balance reached'.tr}'
                  ' ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept)}',
              style: TextStyle(
                color: theme.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
                fontSize: 13,
                fontFamily: AppThemeData.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  Accept / Reject card
// =============================================================================
class _AcceptRejectCard extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  const _AcceptRejectCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final vendor  = ctrl.currentOrder.value.vendor;
    final address = ctrl.currentOrder.value.address;
    double km     = 0.0;
    if (vendor != null && address?.location != null) {
      km = Geolocator.distanceBetween(
        vendor.latitude ?? 0.0,
        vendor.longitude ?? 0.0,
        address!.location!.latitude ?? 0.0,
        address.location!.longitude ?? 0.0,
      ) /
          1000;
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: ShapeDecoration(
          color:
          theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeline(vendor, address),
              const SizedBox(height: 8),
              MySeparator(
                color: theme.getThem()
                    ? AppThemeData.grey700
                    : AppThemeData.grey200,
              ),
              const SizedBox(height: 8),
              _ChargeBreakdown(ctrl: ctrl, theme: theme, km: km),
              const SizedBox(height: 10),
              SafeArea(
                child: Row(children: [
                  Expanded(
                    child: RoundedButtonFill(
                      title: 'Reject'.tr,
                      width: 24,
                      height: 5.5,
                      borderRadius: 10,
                      color: AppThemeData.danger300,
                      textColor: AppThemeData.grey50,
                      onPress: () => ctrl.rejectOrder(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RoundedButtonFill(
                      title: 'Accept'.tr,
                      width: 24,
                      height: 5.5,
                      borderRadius: 10,
                      color: AppThemeData.success400,
                      textColor: AppThemeData.grey50,
                      onPress: () async => ctrl.acceptOrder(),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(vendor, address) {
    return Timeline.tileBuilder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      theme: TimelineThemeData(nodePosition: 0),
      builder: TimelineTileBuilder.connected(
        contentsAlign: ContentsAlign.basic,
        indicatorBuilder: (_, index) => index == 0
            ? _circleIcon('assets/icons/ic_building.svg',
            AppThemeData.primary50, AppThemeData.primary300)
            : _circleIcon('assets/icons/ic_location.svg',
            AppThemeData.driverApp50, AppThemeData.driverApp300),
        connectorBuilder: (_, __, ___) =>
        const DashedLineConnector(color: AppThemeData.grey300, gap: 3),
        contentsBuilder: (ctx, index) => Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: index == 0
                ? [
              Text('${vendor?.title ?? 'N/A'}',
                  style: _titleStyle()),
              Text('${vendor?.location ?? 'N/A'}',
                  style: _subtitleStyle()),
            ]
                : [
              Text('Deliver to the'.tr, style: _titleStyle()),
              Text(address?.getFullAddress() ?? 'N/A',
                  style: _subtitleStyle()),
            ],
          ),
        ),
        itemCount: 2,
      ),
    );
  }

  Widget _circleIcon(String asset, Color bg, Color ic) => Container(
    decoration: ShapeDecoration(
      color: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(120)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: SvgPicture.asset(asset,
          colorFilter: ColorFilter.mode(ic, BlendMode.srcIn)),
    ),
  );

  TextStyle _titleStyle() => TextStyle(
    fontFamily: AppThemeData.semiBold,
    fontSize: 16,
    color:
    theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
  );

  TextStyle _subtitleStyle() => TextStyle(
    fontFamily: AppThemeData.medium,
    fontSize: 14,
    color: theme.getThem()
        ? AppThemeData.grey300
        : AppThemeData.grey600,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Charge breakdown — reads Rx, zero extra API calls on rebuild
// ─────────────────────────────────────────────────────────────────────────────
class _ChargeBreakdown extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  final double km;
  const _ChargeBreakdown(
      {required this.ctrl, required this.theme, required this.km});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tip      = double.tryParse(
          ctrl.currentOrder.value.tipAmount?.toString() ?? '0') ??
          0.0;
      final surge    = ctrl.surgeFee.value;
      final hasSurge = surge > 0;
      final d2r      = ctrl.driverToRestaurantCharge.value;
      final r2c      = ctrl.restaurantToCustomerCharge.value;
      final total    = d2r + r2c + tip + surge;
      final isVendorDriver =
          ctrl.driverModel.value.vendorID?.isEmpty == true;

      return Column(children: [
        // Distance
        _row('Trip Distance'.tr,
            '${km.toStringAsFixed(2)} ${Constant.distanceType}'),

        // Tip
        if (tip > 0) ...[
          const SizedBox(height: 4),
          _row('Tips'.tr, Constant.amountShow(amount: tip.toString())),
        ],
        const SizedBox(height: 6),

        // Delivery charge breakdown
        if (isVendorDriver) ...[
          _row(
            'Delivery Charge'.tr,
            '${d2r.toStringAsFixed(2)} + ${r2c.toStringAsFixed(2)} = ${(d2r + r2c).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 4),
        ],

        // Surge
        if (hasSurge) _surgeRow(surge),

        const SizedBox(height: 8),
        _totalEarningsBox(total),
      ]);
    });
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(
        child: Text(label,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: theme.getThem()
                  ? AppThemeData.grey300
                  : AppThemeData.grey600,
              fontSize: 15,
            )),
      ),
      Text(value,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            color: theme.getThem()
                ? AppThemeData.grey50
                : AppThemeData.grey900,
            fontSize: 15,
          )),
    ]),
  );

  Widget _surgeRow(double surge) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding:
    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    decoration: BoxDecoration(
      color: AppThemeData.success50.withOpacity(0.3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(children: [
      Expanded(
        child: Row(children: [
          Text('Surge Fee'.tr,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                color: theme.getThem()
                    ? AppThemeData.grey300
                    : AppThemeData.grey600,
                fontSize: 15,
              )),
          const SizedBox(width: 6),
          const Icon(Icons.trending_up_rounded,
              color: AppThemeData.success400, size: 16),
        ]),
      ),
      Text('+${surge.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.success500,
            fontSize: 16,
          )),
    ]),
  );

  Widget _totalEarningsBox(double total) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: AppThemeData.primary50.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppThemeData.primary200),
    ),
    child: Row(children: [
      Expanded(
        child: Text('Total Earnings'.tr,
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              color: theme.getThem()
                  ? AppThemeData.grey50
                  : AppThemeData.grey900,
              fontSize: 16,
            )),
      ),
      Text(
        total.toStringAsFixed(2),
        style: const TextStyle(
          fontFamily: AppThemeData.bold,
          color: AppThemeData.primary500,
          fontSize: 20,
        ),
      ),
    ]),
  );
}

// =============================================================================
//  Order actions card (active / in-progress orders)
// =============================================================================
class _OrderActionsCard extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  const _OrderActionsCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final order = ctrl.currentOrder.value;
    return Container(
      color: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Collapse handle
        GestureDetector(
          onTap: ctrl.changeArrow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Obx(() => Icon(
              ctrl.arrowDrop.value
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: theme.getThem()
                  ? AppThemeData.grey300
                  : AppThemeData.grey600,
            )),
          ),
        ),

        // Expandable content
        Obx(() => AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: ctrl.arrowDrop.value
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _OrderCardContent(
                ctrl: ctrl, theme: theme, order: order),
          ),
          secondChild: const SizedBox.shrink(),
        )),

        // Navigation section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: _NavigationSection(ctrl: ctrl, theme: theme, order: order),
        ),

        // Action button
        _ActionButton(ctrl: ctrl, theme: theme, order: order),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OrderCardContent extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  final OrderModel order;
  const _OrderCardContent(
      {required this.ctrl, required this.theme, required this.order});

  @override
  Widget build(BuildContext context) {
    final isPickup = order.status == Constant.orderShipped ||
        order.status == Constant.driverAccepted;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (isPickup) _buildPickupRow() else _buildDeliveryTimeline(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: MySeparator(
          color: theme.getThem()
              ? AppThemeData.grey700
              : AppThemeData.grey200,
        ),
      ),
      _paymentSection(),
      const SizedBox(height: 4),
    ]);
  }

  Widget _buildPickupRow() => Row(children: [
    _circleIcon('assets/icons/ic_building.svg', AppThemeData.primary50,
        AppThemeData.primary300),
    const SizedBox(width: 10),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${order.vendor?.title}', style: _titleStyle()),
        Text('${order.vendor?.location}', style: _subtitleStyle()),
      ]),
    ),
    const SizedBox(width: 8),
    _phoneBtn(() => Constant.makePhoneCall(
        order.vendor!.phonenumber.toString())),
  ]);

  Widget _buildDeliveryTimeline() => Timeline.tileBuilder(
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    theme: TimelineThemeData(nodePosition: 0),
    builder: TimelineTileBuilder.connected(
      contentsAlign: ContentsAlign.basic,
      indicatorBuilder: (_, i) => i == 0
          ? _circleIcon('assets/icons/ic_building.svg',
          AppThemeData.primary50, AppThemeData.primary300)
          : _circleIcon('assets/icons/ic_location.svg',
          AppThemeData.driverApp50, AppThemeData.driverApp300),
      connectorBuilder: (_, __, ___) => const DashedLineConnector(
          color: AppThemeData.grey300, gap: 3),
      contentsBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: i == 0
            ? Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${order.vendor?.title}',
                      style: _titleStyle()),
                  Text(
                    '${order.vendor?.location ?? 'N/A'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _subtitleStyle(),
                  ),
                ]),
          ),
          _phoneBtn(() => Constant.makePhoneCall(
              order.vendor!.phonenumber.toString())),
        ])
            : Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deliver to the'.tr, style: _titleStyle()),

                  ExpandableAddressText(
                    text: order.address?.getFullAddress() ?? 'N/A',
                    style: _subtitleStyle(),
                  ),
                ],
              ),
            ),

            _phoneBtn(() async {
              ShowToastDialog.showLoader('Please wait'.tr);
              final c = await FireStoreUtils.getUserProfile(
                  order.authorID.toString());
              ShowToastDialog.closeLoader();
              if (c?.phoneNumber != null) {
                Constant.makePhoneCall(c!.phoneNumber!);
              }
            }),

            const SizedBox(width: 8),
            _chatBtn(ctx),
          ],
        ),      ),
      itemCount: 2,
    ),
  );

  Widget _chatBtn(BuildContext ctx) => InkWell(
    onTap: () async {
      ShowToastDialog.showLoader('Please wait'.tr);
      final customer = await FireStoreUtils.getUserProfile(
          order.authorID.toString());
      final driver = await FireStoreUtils.getUserProfile(
          order.driverID.toString());
      ShowToastDialog.closeLoader();
      Get.to(const ChatScreen(), arguments: {
        'customerName': customer?.fullName() ?? '',
        'restaurantName': driver?.fullName() ?? '',
        'orderId': order.id,
        'restaurantId': driver?.id,
        'customerId': customer?.id,
        'customerProfileImage': customer?.profilePictureURL ?? '',
        'restaurantProfileImage': driver?.profilePictureURL ?? '',
        'token': customer?.fcmToken,
        'chatType': 'Driver',
      });
    },
    child: _iconCircle(
        child: SvgPicture.asset('assets/icons/ic_wechat.svg')),
  );

  Widget _paymentSection() => Column(children: [
    _payRow(
      'Payment Type'.tr,
      order.paymentMethod?.toLowerCase() == 'cod'
          ? 'Cash on delivery'
          : 'Online',
    ),
    if (order.paymentMethod?.toLowerCase() == 'cod') ...[
      const SizedBox(height: 4),
      Obx(() => _payRow(
        'Collect Payment from customer'.tr,
        Constant.amountShow(
            amount: ctrl.toPayAmount.value.toString()),
      )),
    ],
  ]);

  Widget _payRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(
        child: Text(label,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: theme.getThem()
                  ? AppThemeData.grey300
                  : AppThemeData.grey600,
              fontSize: 15,
            )),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            color: theme.getThem()
                ? AppThemeData.grey50
                : AppThemeData.grey900,
            fontSize: 15,
          ),
        ),
      ),
    ]),
  );

  Widget _phoneBtn(VoidCallback onTap) =>
      InkWell(onTap: onTap, child: _iconCircle(child: SvgPicture.asset('assets/icons/ic_phone_call.svg')));

  Widget _iconCircle({required Widget child}) => Container(
    width: 42,
    height: 42,
    decoration: ShapeDecoration(
      shape: RoundedRectangleBorder(
        side: BorderSide(
            width: 1,
            color: theme.getThem()
                ? AppThemeData.grey700
                : AppThemeData.grey200),
        borderRadius: BorderRadius.circular(120),
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(9), child: child),
  );

  Widget _circleIcon(String asset, Color bg, Color ic) => Container(
    decoration: ShapeDecoration(
      color: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(120)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: SvgPicture.asset(asset,
          colorFilter: ColorFilter.mode(ic, BlendMode.srcIn)),
    ),
  );

  TextStyle _titleStyle() => TextStyle(
    fontFamily: AppThemeData.semiBold,
    fontSize: 16,
    color:
    theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
  );
  TextStyle _subtitleStyle() => TextStyle(
    fontFamily: AppThemeData.medium,
    fontSize: 14,
    color: theme.getThem()
        ? AppThemeData.grey300
        : AppThemeData.grey600,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Navigation section
// ─────────────────────────────────────────────────────────────────────────────
class _NavigationSection extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  final OrderModel order;
  const _NavigationSection(
      {required this.ctrl, required this.theme, required this.order});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPickup = ctrl.isPickupNavigationState;
      final isDrop   = ctrl.isDropNavigationState;
      if (!isPickup && !isDrop) return const SizedBox.shrink();

      final destLat = isPickup
          ? order.vendor?.latitude
          : order.address?.location?.latitude;
      final canNav  = destLat != null;

      return Container(
        decoration: BoxDecoration(
          color: theme.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Pickup'.tr, order.vendor?.location ?? 'N/A'),
              const SizedBox(height: 4),
              _infoRow(
                  'Drop'.tr, order.address?.getFullAddress() ?? 'N/A'),
              const SizedBox(height: 8),
          Center(
            child: RoundedButtonFill(
                title: ctrl.isNavigatingToMap.value
                    ? 'Opening Maps...'.tr
                    : (isPickup
                    ? 'Navigate to Restaurant'.tr
                    : 'Navigate to Customer'.tr),
                width: 45,
                height: 5,
                borderRadius: 10,
                color: canNav
                    ? AppThemeData.primary300
                    : AppThemeData.grey400,
                textColor: AppThemeData.grey50,
                onPress: (!canNav || ctrl.isNavigatingToMap.value)
                    ? null
                    : () => ctrl.openCurrentOrderNavigation(),
            ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _infoRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 52,
        child: Text(label,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              fontSize: 12,
              color: theme.getThem()
                  ? AppThemeData.grey300
                  : AppThemeData.grey600,
            )),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              fontSize: 13,
              color: theme.getThem()
                  ? AppThemeData.grey50
                  : AppThemeData.grey900,
            )),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom action button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  final OrderModel order;
  const _ActionButton(
      {required this.ctrl, required this.theme, required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: SafeArea(
        child: Container(
          color: AppThemeData.driverApp300,
          width: Responsive.width(100, context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _label(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppThemeData.grey900,
              fontSize: 16,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  String _label() {
    final s = order.status ?? '';
    if (s == Constant.orderShipped || s == Constant.driverAccepted) {
      return 'Reached restaurant for Pickup'.tr;
    }
    if (s == Constant.orderInTransit) {
      return ctrl.driverModel.value.vendorID?.isEmpty == true
          ? 'Reached the Customers Door Steps'.tr
          : 'Order Delivered'.tr;
    }
    if (s == Constant.driverPending) return 'Reached restaurant for Pickup'.tr;
    return 'Order Delivered'.tr;
  }

  Future<void> _handleTap(BuildContext ctx) async {
    final s = order.status ?? '';
    if (s == Constant.orderShipped || s == Constant.driverAccepted) {
      final result = await Get.to(
        const PickupOrderScreen(),
        arguments: {'orderModel': order},
      );
      if (result == true) {
        final cached = ctrl.currentOrder.value;
        cached.status = Constant.orderInTransit;
        ctrl.currentOrder.value = cached;
        ctrl.currentOrder.refresh();
        await Future.delayed(const Duration(milliseconds: 800));
        await ctrl.refreshCurrentOrder(forceRefresh: true);
      }
      return;
    }

    final result = await Get.to(
      const DeliverOrderScreen(),
      arguments: {'orderModel': order},
    );
    if (result == true || result is String) {
      final completedId =
          (result is String ? result : null) ?? order.id?.toString();
      if (completedId != null) {
        ctrl.markOrderAsCompleted(completedId);
        ctrl.driverModel.value.inProgressOrderID
            ?.removeWhere((id) => id?.toString() == completedId);
        ctrl.driverModel.value.orderRequestData
            ?.removeWhere((id) => id?.toString() == completedId);
        final h = HttpClientService();
        await h.invalidateCache('orders/$completedId');
      }
      await FireStoreUtils.updateUser(ctrl.driverModel.value);
      ctrl.currentOrder.value = OrderModel();
      await ctrl.clearMap();
      ctrl.resetStatusTracking();
      ctrl.update();
      if (Constant.singleOrderReceive == false) Get.back();
    }
  }
}

// =============================================================================
//  PiP overlay — minimal: status + earnings only
// =============================================================================
class _PipOverlay extends StatelessWidget {
  final HomeController ctrl;
  final DarkThemeProvider theme;
  const _PipOverlay({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final order = ctrl.currentOrder.value;
    if (order.id == null) return const SizedBox.shrink();
    return Container(
      color: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        const Icon(Icons.delivery_dining,
            size: 22, color: AppThemeData.secondary300),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            order.status ?? '',
            style: TextStyle(
              color: theme.getThem()
                  ? AppThemeData.grey50
                  : AppThemeData.grey900,
              fontSize: 14,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
        ),
        Obx(() => Text(
          ctrl.totalCalculatedCharge.value.toInt().toString(),
          style: const TextStyle(
            color: AppThemeData.primary500,
            fontSize: 18,
            fontFamily: AppThemeData.bold,
          ),
        )),
      ]),
    );
  }
}