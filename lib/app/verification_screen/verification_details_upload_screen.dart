// import 'dart:io';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
// import 'package:jippydriver_driver/controllers/verification_details_upload_controller.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:jippydriver_driver/themes/responsive.dart';
// import 'package:jippydriver_driver/themes/round_button_fill.dart';
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
//
// class VerificationDetailsUploadScreen extends StatelessWidget {
//   const VerificationDetailsUploadScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return GetX<DetailsUploadController>(
//         init: DetailsUploadController(),
//         builder: (controller) {
//           return SafeArea(
//             child: Scaffold(
//               appBar: AppBar(
//                 backgroundColor: themeChange.getThem()
//                     ? AppThemeData.grey900
//                     : AppThemeData.grey50,
//                 centerTitle: false,
//                 automaticallyImplyLeading: false,
//                 titleSpacing: 0,
//                 leading: InkWell(
//                   onTap: () {
//                     Get.back();
//                   },
//                   child: Icon(
//                     Icons.chevron_left_outlined,
//                     color: themeChange.getThem()
//                         ? AppThemeData.grey50
//                         : AppThemeData.grey900,
//                   ),
//                 ),
//                 title: Text(
//                   "${controller.documentModel.value.title}",
//                   style: TextStyle(
//                       color: themeChange.getThem()
//                           ? AppThemeData.grey100
//                           : AppThemeData.grey800,
//                       fontFamily: AppThemeData.bold,
//                       fontSize: 18),
//                 ),
//                 elevation: 0,
//               ),
//               body: controller.isLoading.value
//                   ? Constant.loader()
//                   : SingleChildScrollView(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 10),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "${'Upload'.tr} ${controller.documentModel.value.title} ${'for Verification'.tr}",
//                               style: TextStyle(
//                                   color: themeChange.getThem()
//                                       ? AppThemeData.grey100
//                                       : AppThemeData.grey800,
//                                   fontFamily: AppThemeData.bold,
//                                   fontSize: 22),
//                             ),
//                             const SizedBox(
//                               height: 5,
//                             ),
//                             Text(
//                               "${'Please upload a valid'.tr} ${controller.documentModel.value.title} ${'to verify your identity complete the registration process.'.tr}"
//                                   .tr,
//                               style: TextStyle(
//                                   fontSize: 16,
//                                   color: themeChange.getThem()
//                                       ? AppThemeData.grey200
//                                       : AppThemeData.grey700,
//                                   fontFamily: AppThemeData.regular),
//                             ),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             Visibility(
//                               visible:
//                                   controller.documentModel.value.frontSide == true
//                                       ? true
//                                       : false,
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 10),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "${'Front Side of'} ${controller.documentModel.value.title.toString()}",
//                                       style: TextStyle(
//                                           color: themeChange.getThem()
//                                               ? AppThemeData.grey50
//                                               : AppThemeData.grey900,
//                                           fontFamily: AppThemeData.bold,
//                                           fontSize: 16),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     controller.frontImage.value.isNotEmpty
//                                         ? InkWell(
//                                             onTap: () {
//                                               if (controller.documents.value
//                                                           .status !=
//                                                       "uploaded" ||
//                                                   controller.documents.value
//                                                           .status ==
//                                                       "rejected") {
//                                                 buildBottomSheet(
//                                                     context, controller, "front");
//                                               }
//                                             },
//                                             child: SizedBox(
//                                               height:
//                                                   Responsive.height(20, context),
//                                               width:
//                                                   Responsive.width(90, context),
//                                               child: ClipRRect(
//                                                 borderRadius:
//                                                     const BorderRadius.all(
//                                                         Radius.circular(10)),
//                                                 child: Constant().hasValidUrl(
//                                                             controller.frontImage
//                                                                 .value) ==
//                                                         false
//                                                     ? Image.file(
//                                                         File(controller
//                                                             .frontImage.value),
//                                                         height: Responsive.height(
//                                                             20, context),
//                                                         width: Responsive.width(
//                                                             80, context),
//                                                         fit: BoxFit.fill,
//                                                       )
//                                                     : CachedNetworkImage(
//                                                         imageUrl: controller
//                                                             .frontImage.value
//                                                             .toString(),
//                                                         fit: BoxFit.fill,
//                                                         height: Responsive.height(
//                                                             20, context),
//                                                         width: Responsive.width(
//                                                             80, context),
//                                                         placeholder:
//                                                             (context, url) =>
//                                                                 Constant.loader(),
//                                                         errorWidget: (context,
//                                                                 url, error) =>
//                                                             Image.network(
//                                                                 'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
//                                                       ),
//                                               ),
//                                             ),
//                                           )
//                                         : DottedBorder(
//                                       options: RectDottedBorderOptions(
//                                         dashPattern: const [6, 6, 6, 6],
//                                         strokeWidth: 2,
//                                           color: themeChange.getThem()
//                                             ? AppThemeData.grey700
//                                             : AppThemeData.grey200,
//                                       ),
//                                             // borderType: BorderType.RRect,
//                                             // radius: const Radius.circular(12),
//                                             // dashPattern: const [6, 6, 6, 6],
//                                             // color: themeChange.getThem()
//                                             //     ? AppThemeData.grey700
//                                             //     : AppThemeData.grey200,
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 color: themeChange.getThem()
//                                                     ? AppThemeData.grey900
//                                                     : AppThemeData.grey50,
//                                                 borderRadius:
//                                                     const BorderRadius.all(
//                                                   Radius.circular(12),
//                                                 ),
//                                               ),
//                                               child: SizedBox(
//                                                   height: Responsive.height(
//                                                       22, context),
//                                                   width: Responsive.width(
//                                                       90, context),
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment.center,
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment.center,
//                                                     children: [
//                                                       SvgPicture.asset(
//                                                         'assets/icons/ic_folder.svg',
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 10,
//                                                       ),
//                                                       Text(
//                                                         "Choose a image and upload here"
//                                                             .tr,
//                                                         style: TextStyle(
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppThemeData
//                                                                     .grey100
//                                                                 : AppThemeData
//                                                                     .grey800,
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .medium,
//                                                             fontSize: 16),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 5,
//                                                       ),
//                                                       Text(
//                                                         "JPEG, PNG".tr,
//                                                         style: TextStyle(
//                                                             fontSize: 12,
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppThemeData
//                                                                     .grey200
//                                                                 : AppThemeData
//                                                                     .grey700,
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .regular),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 10,
//                                                       ),
//                                                       RoundedButtonFill(
//                                                         title: "Brows Image".tr,
//                                                         color: AppThemeData
//                                                             .driverApp50,
//                                                         textColor: AppThemeData
//                                                             .driverApp300,
//                                                         width: 30,
//                                                         height: 5,
//                                                         onPress: () async {
//                                                           buildBottomSheet(
//                                                               context,
//                                                               controller,
//                                                               "front");
//                                                         },
//                                                       ),
//                                                     ],
//                                                   )),
//                                             ),
//                                           ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Visibility(
//                               visible:
//                                   controller.documentModel.value.backSide == true
//                                       ? true
//                                       : false,
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 10),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "${'Back side of'.tr} ${controller.documentModel.value.title.toString()}",
//                                       style: TextStyle(
//                                           color: themeChange.getThem()
//                                               ? AppThemeData.grey50
//                                               : AppThemeData.grey900,
//                                           fontFamily: AppThemeData.bold,
//                                           fontSize: 16),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     controller.backImage.value.isNotEmpty
//                                         ? InkWell(
//                                             onTap: () {
//                                               if (controller.documents.value
//                                                           .status !=
//                                                       "uploaded" ||
//                                                   controller.documents.value
//                                                           .status ==
//                                                       "rejected") {
//                                                 buildBottomSheet(
//                                                     context, controller, "back");
//                                               }
//                                             },
//                                             child: SizedBox(
//                                               height:
//                                                   Responsive.height(20, context),
//                                               width:
//                                                   Responsive.width(90, context),
//                                               child: ClipRRect(
//                                                 borderRadius:
//                                                     const BorderRadius.all(
//                                                         Radius.circular(10)),
//                                                 child: Constant().hasValidUrl(
//                                                             controller.backImage
//                                                                 .value) ==
//                                                         false
//                                                     ? Image.file(
//                                                         File(controller
//                                                             .backImage.value),
//                                                         height: Responsive.height(
//                                                             20, context),
//                                                         width: Responsive.width(
//                                                             80, context),
//                                                         fit: BoxFit.fill,
//                                                       )
//                                                     : CachedNetworkImage(
//                                                         imageUrl: controller
//                                                             .backImage.value
//                                                             .toString(),
//                                                         fit: BoxFit.fill,
//                                                         height: Responsive.height(
//                                                             20, context),
//                                                         width: Responsive.width(
//                                                             80, context),
//                                                         placeholder:
//                                                             (context, url) =>
//                                                                 Constant.loader(),
//                                                         errorWidget: (context,
//                                                                 url, error) =>
//                                                             Image.network(
//                                                                 'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
//                                                       ),
//                                               ),
//                                             ),
//                                           )
//                                         : DottedBorder(
//                                       options: RectDottedBorderOptions(
//                                         dashPattern: const [6, 6, 6, 6],
//                                         strokeWidth: 2,
//                                         color: themeChange.getThem()
//                                             ? AppThemeData.grey700
//                                             : AppThemeData.grey200,
//                                       ),
//                                             // borderType: BorderType.RRect,
//                                             // radius: const Radius.circular(12),
//                                             // dashPattern: const [6, 6, 6, 6],
//                                             // color: themeChange.getThem()
//                                             //     ? AppThemeData.grey700
//                                             //     : AppThemeData.grey200,
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 color: themeChange.getThem()
//                                                     ? AppThemeData.grey900
//                                                     : AppThemeData.grey50,
//                                                 borderRadius:
//                                                     const BorderRadius.all(
//                                                   Radius.circular(12),
//                                                 ),
//                                               ),
//                                               child: SizedBox(
//                                                   height: Responsive.height(
//                                                       22, context),
//                                                   width: Responsive.width(
//                                                       90, context),
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment.center,
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment.center,
//                                                     children: [
//                                                       SvgPicture.asset(
//                                                         'assets/icons/ic_folder.svg',
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 10,
//                                                       ),
//                                                       Text(
//                                                         "Choose a image and upload here"
//                                                             .tr,
//                                                         style: TextStyle(
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppThemeData
//                                                                     .grey100
//                                                                 : AppThemeData
//                                                                     .grey800,
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .medium,
//                                                             fontSize: 16),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 5,
//                                                       ),
//                                                       Text(
//                                                         "JPEG, PNG".tr,
//                                                         style: TextStyle(
//                                                             fontSize: 12,
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppThemeData
//                                                                     .grey200
//                                                                 : AppThemeData
//                                                                     .grey700,
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .regular),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 10,
//                                                       ),
//                                                       RoundedButtonFill(
//                                                         title: "Brows Image".tr,
//                                                         color: AppThemeData
//                                                             .driverApp50,
//                                                         textColor: AppThemeData
//                                                             .driverApp300,
//                                                         width: 30,
//                                                         height: 5,
//                                                         onPress: () async {
//                                                           buildBottomSheet(
//                                                               context,
//                                                               controller,
//                                                               "back");
//                                                         },
//                                                       ),
//                                                     ],
//                                                   )),
//                                             ),
//                                           ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(
//                               height: 30,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//               bottomNavigationBar: controller.documents.value.status ==
//                           "approved" ||
//                       controller.documents.value.status == "uploaded"
//                   ? const SizedBox()
//                   : InkWell(
//                       onTap: () {
//                         if (controller.documentModel.value.frontSide == true &&
//                             controller.frontImage.value.isEmpty) {
//                           ShowToastDialog.showToast(
//                               "Please upload front side of document.".tr);
//                         } else if (controller.documentModel.value.backSide ==
//                                 true &&
//                             controller.backImage.value.isEmpty) {
//                           ShowToastDialog.showToast(
//                               "Please upload back side of document.".tr);
//                         } else {
//                           ShowToastDialog.showLoader("Please wait..".tr);
//                           controller.uploadDocument();
//                         }
//                       },
//                       child: Container(
//                         color: AppThemeData.driverApp300,
//                         width: Responsive.width(100, context),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           child: Text(
//                             "Upload Document".tr,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey50
//                                   : AppThemeData.grey50,
//                               fontSize: 16,
//                               fontFamily: AppThemeData.medium,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//             ),
//           );
//         });
//   }
//
//   buildBottomSheet(
//       BuildContext context, DetailsUploadController controller, String type) {
//     return showModalBottomSheet(
//         context: context,
//         builder: (context) {
//           final themeChange = Provider.of<DarkThemeProvider>(context);
//           return StatefulBuilder(builder: (context, setState) {
//             return SizedBox(
//               height: Responsive.height(22, context),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(top: 15),
//                     child: Text(
//                       "Please Select".tr,
//                       style: TextStyle(
//                           color: themeChange.getThem()
//                               ? AppThemeData.grey50
//                               : AppThemeData.grey900,
//                           fontFamily: AppThemeData.bold,
//                           fontSize: 16),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(18.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             IconButton(
//                                 onPressed: () => controller.pickFile(
//                                     source: ImageSource.camera, type: type),
//                                 icon: const Icon(
//                                   Icons.camera_alt,
//                                   size: 32,
//                                 )),
//                             Padding(
//                               padding: const EdgeInsets.only(top: 3),
//                               child: Text("Camera".tr),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(18.0),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             IconButton(
//                                 onPressed: () => controller.pickFile(
//                                     source: ImageSource.gallery, type: type),
//                                 icon: const Icon(
//                                   Icons.photo_library_sharp,
//                                   size: 32,
//                                 )),
//                             Padding(
//                               padding: const EdgeInsets.only(top: 3),
//                               child: Text("Gallery".tr),
//                             ),
//                           ],
//                         ),
//                       )
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           });
//         });
//   }
// }



import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/controllers/verification_details_upload_controller.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';

class VerificationDetailsUploadScreen extends StatelessWidget {
  const VerificationDetailsUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    return GetX<DetailsUploadController>(
      init: DetailsUploadController(),
      builder: (controller) {
        final isAadhaar = controller.isAadhaarDocument;
        final isSelfieOnly = controller.isSelfieOnly.value;
        final docStatus = controller.documents.value.status;
        final isDocLocked =
            docStatus == "approved" || docStatus == "uploaded";
        final isLocked = isSelfieOnly ? false : isDocLocked;

        return Scaffold(
          backgroundColor:
          isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
          appBar: _buildAppBar(controller, isDark),
          body: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildDocHeader(controller, isDark),
              ),
              // ── Aadhaar flow ──────────────────────────────
              if (!isSelfieOnly && isAadhaar)
                SliverToBoxAdapter(
                  child: _AadhaarSection(
                      controller: controller, isDark: isDark),
                ),
              // ── Non-Aadhaar: normal upload ────────────────
              if (!isSelfieOnly && !isAadhaar) ...[
                if (controller.documentModel.value.frontSide == true)
                  SliverToBoxAdapter(
                    child: _ImageUploadTile(
                      label:
                      "Front Side of ${controller.documentModel.value.title}",
                      imagePath: controller.frontImage.value,
                      isDark: isDark,
                      isLocked: isLocked,
                      onTap: () => _showSourceSheet(
                          context, controller, "front"),
                    ),
                  ),
                if (controller.documentModel.value.backSide == true)
                  SliverToBoxAdapter(
                    child: _ImageUploadTile(
                      label:
                      "Back Side of ${controller.documentModel.value.title}",
                      imagePath: controller.backImage.value,
                      isDark: isDark,
                      isLocked: isLocked,
                      onTap: () =>
                          _showSourceSheet(context, controller, "back"),
                    ),
                  ),
              ],
              // ── Selfie (only on dedicated selfie tab) ─────
              if (isSelfieOnly)
                SliverToBoxAdapter(
                  child: _SelfieTile(
                      controller: controller,
                      isDark: isDark,
                      isLocked: isLocked,
                      context: context),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          bottomNavigationBar: (isDocLocked && !isSelfieOnly)
              ? const SizedBox(height: 0)
              : _buildSubmitButton(controller, isDark),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────
  // App Bar
  // ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      DetailsUploadController controller, bool isDark) {
    final title = controller.isSelfieOnly.value
        ? "Selfie / Profile Photo".tr
        : "${controller.documentModel.value.title}";
    return AppBar(
      backgroundColor:
      isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
          fontFamily: AppThemeData.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────
  Widget _buildDocHeader(DetailsUploadController controller, bool isDark) {
    final isSelfieOnly = controller.isSelfieOnly.value;
    final title = isSelfieOnly
        ? "Upload Selfie / Profile Photo".tr
        : "${'Upload'.tr} ${controller.documentModel.value.title}";
    final subtitle = isSelfieOnly
        ? "Please upload a clear selfie. This will be used as your profile photo."
            .tr
        : "Please upload a clear, valid document to verify your identity.".tr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
              fontFamily: AppThemeData.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
              fontFamily: AppThemeData.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // Submit button
  // ─────────────────────────────────────────────────
  Widget _buildSubmitButton(
      DetailsUploadController controller, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => controller.onSubmitPressed(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeData.driverApp300,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            "Upload Document".tr,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.medium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // Bottom Sheet (camera / gallery)
  // ─────────────────────────────────────────────────
  static void _showSourceSheet(
      BuildContext context, DetailsUploadController controller, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark =
        Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Select Image Source".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    isDark: isDark,
                    onTap: () => controller.pickFile(
                        source: ImageSource.camera, type: type),
                  ),
                  _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    isDark: isDark,
                    onTap: () => controller.pickFile(
                        source: ImageSource.gallery, type: type),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image Upload Tile
// ─────────────────────────────────────────────────────────────
class _ImageUploadTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final bool isDark;
  final bool isLocked;
  final VoidCallback onTap;

  const _ImageUploadTile({
    required this.label,
    required this.imagePath,
    required this.isDark,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty;
    final isUrl = Constant().hasValidUrl(imagePath);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppThemeData.grey200 : AppThemeData.grey800,
                fontFamily: AppThemeData.bold,
                fontSize: 15,
              ),
            ),
          ),
          hasImage
              ? _ImagePreview(
            imagePath: imagePath,
            isUrl: isUrl,
            isDark: isDark,
            isLocked: isLocked,
            onTap: onTap,
          )
              : _EmptyUpload(isDark: isDark, onTap: onTap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image Preview
// ─────────────────────────────────────────────────────────────
class _ImagePreview extends StatelessWidget {
  final String imagePath;
  final bool isUrl;
  final bool isDark;
  final bool isLocked;
  final VoidCallback onTap;

  const _ImagePreview({
    required this.imagePath,
    required this.isUrl,
    required this.isDark,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            SizedBox(
              height: Responsive.height(22, context),
              width: double.infinity,
              child: isUrl
                  ? CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              )
                  : Image.file(File(imagePath), fit: BoxFit.cover),
            ),
            if (!isLocked)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty Upload Placeholder
// ─────────────────────────────────────────────────────────────
class _EmptyUpload extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _EmptyUpload({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        options: RectDottedBorderOptions(
          dashPattern: const [6, 5],
          strokeWidth: 1.5,
          color: isDark ? AppThemeData.grey600 : AppThemeData.grey300,
        ),
        child: Container(
          height: Responsive.height(20, context),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? AppThemeData.grey900.withOpacity(0.5)
                : AppThemeData.grey50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppThemeData.driverApp300.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_photo_alternate_rounded,
                    color: AppThemeData.driverApp300, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                "Tap to upload image".tr,
                style: TextStyle(
                  color:
                  isDark ? AppThemeData.grey300 : AppThemeData.grey700,
                  fontFamily: AppThemeData.medium,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "JPEG or PNG",
                style: TextStyle(
                  fontSize: 12,
                  color:
                  isDark ? AppThemeData.grey500 : AppThemeData.grey500,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Selfie Tile
// ─────────────────────────────────────────────────────────────
class _SelfieTile extends StatelessWidget {
  final DetailsUploadController controller;
  final bool isDark;
  final bool isLocked;
  final BuildContext context;

  const _SelfieTile({
    required this.controller,
    required this.isDark,
    required this.isLocked,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final selfie = controller.selfieImage.value;
    final hasSelfie = selfie.isNotEmpty;
    final isUrl = Constant().hasValidUrl(selfie);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.face_retouching_natural_rounded,
                    size: 18, color: AppThemeData.driverApp300),
                const SizedBox(width: 6),
                Text(
                  "Selfie / Profile Photo",
                  style: TextStyle(
                    color:
                    isDark ? AppThemeData.grey200 : AppThemeData.grey800,
                    fontFamily: AppThemeData.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          hasSelfie
              ? GestureDetector(
            onTap: isLocked
                ? null
                : () => _pickSelfie(context, controller),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: isUrl
                        ? CachedNetworkImage(
                        imageUrl: selfie, fit: BoxFit.cover)
                        : Image.file(File(selfie), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selfie uploaded",
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 14,
                          color: isDark
                              ? AppThemeData.grey100
                              : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isLocked)
                        TextButton.icon(
                          onPressed: () =>
                              _pickSelfie(context, controller),
                          icon: const Icon(Icons.refresh_rounded,
                              size: 14),
                          label: const Text("Retake"),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppThemeData.driverApp300,
                            tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
              : GestureDetector(
            onTap: () => _pickSelfie(context, controller),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeData.grey900.withOpacity(0.5)
                    : AppThemeData.grey50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppThemeData.grey700
                      : AppThemeData.grey200,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                      AppThemeData.driverApp300.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child:  Icon(Icons.camera_front_rounded,
                        color: AppThemeData.driverApp300, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Take a selfie",
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 15,
                      color: isDark
                          ? AppThemeData.grey300
                          : AppThemeData.grey700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "This will be used as your profile photo",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppThemeData.grey500
                          : AppThemeData.grey500,
                      fontFamily: AppThemeData.regular,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickSelfie(
      BuildContext context, DetailsUploadController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark =
        Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Upload Selfie".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color:
                  isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceOption(
                    icon: Icons.camera_front_rounded,
                    label: "Camera",
                    isDark: isDark,
                    onTap: () => controller.pickSelfie(
                        source: ImageSource.camera),
                  ),
                  _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    isDark: isDark,
                    onTap: () => controller.pickSelfie(
                        source: ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Aadhaar Section
// ─────────────────────────────────────────────────────────────
class _AadhaarSection extends StatelessWidget {
  final DetailsUploadController controller;
  final bool isDark;

  const _AadhaarSection(
      {required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        if (controller.aadhaarVerified.value) {
          return _buildVerifiedCard();
        }
        if (controller.aadhaarOtpSent.value) {
          return _buildOtpCard(context);
        }
        return _buildAadhaarInputCard(context);
      }),
    );
  }

  Widget _buildAadhaarInputCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                "Aadhaar Authentication",
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color:
                  isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Enter your 12-digit Aadhaar number to receive an OTP for verification.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
              fontFamily: AppThemeData.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.aadhaarController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            style: TextStyle(
              color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
              fontFamily: AppThemeData.medium,
              fontSize: 18,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: "XXXX XXXX XXXX",
              hintStyle: TextStyle(
                color: isDark ? AppThemeData.grey600 : AppThemeData.grey400,
                letterSpacing: 2,
              ),
              prefixIcon: Icon(Icons.fingerprint_rounded,
                  color: AppThemeData.driverApp300),
              filled: true,
              fillColor: isDark
                  ? AppThemeData.grey800
                  : AppThemeData.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppThemeData.driverApp300, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.aadhaarLoading.value
                  ? null
                  : () => controller.sendAadhaarOtp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.driverApp300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.aadhaarLoading.value
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text(
                "Send OTP",
                style: TextStyle(
                    fontFamily: AppThemeData.medium, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sms_rounded,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                "Enter OTP",
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color:
                  isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "OTP sent to mobile linked with your Aadhaar. Enter it below.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
              fontFamily: AppThemeData.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
              fontFamily: AppThemeData.medium,
              fontSize: 22,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: "• • • • • •",
              hintStyle: TextStyle(
                color: isDark ? AppThemeData.grey600 : AppThemeData.grey400,
                letterSpacing: 4,
              ),
              prefixIcon:  Icon(Icons.lock_rounded,
                  color: AppThemeData.driverApp300),
              filled: true,
              fillColor:
              isDark ? AppThemeData.grey800 : AppThemeData.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppThemeData.driverApp300, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.resetAadhaarFlow(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                        color: isDark
                            ? AppThemeData.grey600
                            : AppThemeData.grey300),
                  ),
                  child: Text(
                    "Back",
                    style: TextStyle(
                      color: isDark
                          ? AppThemeData.grey300
                          : AppThemeData.grey700,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: controller.aadhaarLoading.value
                      ? null
                      : () => controller.verifyAadhaarOtp(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.driverApp300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.aadhaarLoading.value
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    "Verify OTP",
                    style: TextStyle(
                        fontFamily: AppThemeData.medium, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.green, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aadhaar Verified!",
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 15,
                    color:
                    isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Your Aadhaar has been authenticated successfully.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppThemeData.grey400
                        : AppThemeData.grey600,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Source Option (camera / gallery picker button)
// ─────────────────────────────────────────────────────────────
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppThemeData.driverApp300.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppThemeData.driverApp300, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              fontSize: 13,
              color: isDark ? AppThemeData.grey300 : AppThemeData.grey700,
            ),
          ),
        ],
      ),
    );
  }
}