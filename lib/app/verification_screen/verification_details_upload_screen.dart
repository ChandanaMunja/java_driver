// import 'dart:io';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
//
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/controllers/verification_details_upload_controller.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:jippydriver_driver/themes/responsive.dart';
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
//
// class VerificationDetailsUploadScreen extends StatelessWidget {
//   const VerificationDetailsUploadScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     final bool isDark = themeChange.getThem();
//
//     return GetX<DetailsUploadController>(
//       init: DetailsUploadController(),
//       builder: (controller) {
//         final isAadhaar = controller.isAadhaarDocument;
//         final isSelfieOnly = controller.isSelfieOnly.value;
//         final docStatus = controller.documents.value.status;
//         final isDocLocked =
//             docStatus == "approved" || docStatus == "uploaded";
//         final isLocked = isSelfieOnly ? false : isDocLocked;
//
//         return Scaffold(
//           backgroundColor:
//           isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
//           appBar: _buildAppBar(controller, isDark),
//           body: controller.isLoading.value
//               ? const Center(child: CircularProgressIndicator())
//               : CustomScrollView(
//             slivers: [
//               SliverToBoxAdapter(
//                 child: _buildDocHeader(controller, isDark),
//               ),
//               // ── Aadhaar flow ──────────────────────────────
//               if (!isSelfieOnly && isAadhaar)
//                 SliverToBoxAdapter(
//                   child: _AadhaarSection(
//                       controller: controller, isDark: isDark),
//                 ),
//               // ── Non-Aadhaar: normal upload ────────────────
//               if (!isSelfieOnly && !isAadhaar) ...[
//                 if (controller.documentModel.value.frontSide == true)
//                   SliverToBoxAdapter(
//                     child: _ImageUploadTile(
//                       label:
//                       "Front Side of ${controller.documentModel.value.title}",
//                       imagePath: controller.frontImage.value,
//                       isDark: isDark,
//                       isLocked: isLocked,
//                       onTap: () => _showSourceSheet(
//                           context, controller, "front"),
//                     ),
//                   ),
//                 if (controller.documentModel.value.backSide == true)
//                   SliverToBoxAdapter(
//                     child: _ImageUploadTile(
//                       label:
//                       "Back Side of ${controller.documentModel.value.title}",
//                       imagePath: controller.backImage.value,
//                       isDark: isDark,
//                       isLocked: isLocked,
//                       onTap: () =>
//                           _showSourceSheet(context, controller, "back"),
//                     ),
//                   ),
//               ],
//               // ── Selfie (only on dedicated selfie tab) ─────
//               if (isSelfieOnly)
//                 SliverToBoxAdapter(
//                   child: _SelfieTile(
//                       controller: controller,
//                       isDark: isDark,
//                       isLocked: isLocked,
//                       context: context),
//                 ),
//               const SliverToBoxAdapter(child: SizedBox(height: 100)),
//             ],
//           ),
//           bottomNavigationBar: (isDocLocked && !isSelfieOnly)
//               ? const SizedBox(height: 0)
//               : _buildSubmitButton(controller, isDark),
//         );
//       },
//     );
//   }
//
//   // ─────────────────────────────────────────────────
//   // App Bar
//   // ─────────────────────────────────────────────────
//   PreferredSizeWidget _buildAppBar(
//       DetailsUploadController controller, bool isDark) {
//     final title = controller.isSelfieOnly.value
//         ? "Selfie / Profile Photo".tr
//         : "${controller.documentModel.value.title}";
//     return AppBar(
//       backgroundColor:
//       isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
//       elevation: 0,
//       centerTitle: false,
//       automaticallyImplyLeading: false,
//       titleSpacing: 0,
//       leading: IconButton(
//         onPressed: () => Get.back(),
//         icon: Icon(
//           Icons.arrow_back_ios_new_rounded,
//           color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//           size: 20,
//         ),
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//           fontFamily: AppThemeData.bold,
//           fontSize: 18,
//         ),
//       ),
//     );
//   }
//
//   // ─────────────────────────────────────────────────
//   // Header
//   // ─────────────────────────────────────────────────
//   Widget _buildDocHeader(DetailsUploadController controller, bool isDark) {
//     final isSelfieOnly = controller.isSelfieOnly.value;
//     final title = isSelfieOnly
//         ? "Upload Selfie / Profile Photo".tr
//         : "${'Upload'.tr} ${controller.documentModel.value.title}";
//     final subtitle = isSelfieOnly
//         ? "Please upload a clear selfie. This will be used as your profile photo."
//             .tr
//         : "Please upload a clear, valid document to verify your identity.".tr;
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//               fontFamily: AppThemeData.bold,
//               fontSize: 22,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             subtitle,
//             style: TextStyle(
//               fontSize: 14,
//               color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
//               fontFamily: AppThemeData.regular,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
//
//   // ─────────────────────────────────────────────────
//   // Submit button
//   // ─────────────────────────────────────────────────
//   Widget _buildSubmitButton(
//       DetailsUploadController controller, bool isDark) {
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ElevatedButton(
//           onPressed: () => controller.onSubmitPressed(),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppThemeData.driverApp300,
//             foregroundColor: Colors.white,
//             minimumSize: const Size.fromHeight(54),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//             elevation: 0,
//           ),
//           child: Text(
//             "Upload Document".tr,
//             style: const TextStyle(
//               fontSize: 16,
//               fontFamily: AppThemeData.medium,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ─────────────────────────────────────────────────
//   // Bottom Sheet (camera / gallery)
//   // ─────────────────────────────────────────────────
//   static void _showSourceSheet(
//       BuildContext context, DetailsUploadController controller, String type) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         final isDark =
//         Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
//         return Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "Select Image Source".tr,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.bold,
//                   fontSize: 16,
//                   color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _SourceOption(
//                     icon: Icons.camera_alt_rounded,
//                     label: "Camera",
//                     isDark: isDark,
//                     onTap: () => controller.pickFile(
//                         source: ImageSource.camera, type: type),
//                   ),
//                   _SourceOption(
//                     icon: Icons.photo_library_rounded,
//                     label: "Gallery",
//                     isDark: isDark,
//                     onTap: () => controller.pickFile(
//                         source: ImageSource.gallery, type: type),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // Image Upload Tile
// // ─────────────────────────────────────────────────────────────
// class _ImageUploadTile extends StatelessWidget {
//   final String label;
//   final String imagePath;
//   final bool isDark;
//   final bool isLocked;
//   final VoidCallback onTap;
//
//   const _ImageUploadTile({
//     required this.label,
//     required this.imagePath,
//     required this.isDark,
//     required this.isLocked,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final hasImage = imagePath.isNotEmpty;
//     final isUrl = Constant().hasValidUrl(imagePath);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 4, bottom: 10),
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: isDark ? AppThemeData.grey200 : AppThemeData.grey800,
//                 fontFamily: AppThemeData.bold,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//           hasImage
//               ? _ImagePreview(
//             imagePath: imagePath,
//             isUrl: isUrl,
//             isDark: isDark,
//             isLocked: isLocked,
//             onTap: onTap,
//           )
//               : _EmptyUpload(isDark: isDark, onTap: onTap),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // Image Preview
// // ─────────────────────────────────────────────────────────────
// class _ImagePreview extends StatelessWidget {
//   final String imagePath;
//   final bool isUrl;
//   final bool isDark;
//   final bool isLocked;
//   final VoidCallback onTap;
//
//   const _ImagePreview({
//     required this.imagePath,
//     required this.isUrl,
//     required this.isDark,
//     required this.isLocked,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: isLocked ? null : onTap,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(14),
//         child: Stack(
//           children: [
//             SizedBox(
//               height: Responsive.height(22, context),
//               width: double.infinity,
//               child: isUrl
//                   ? CachedNetworkImage(
//                 imageUrl: imagePath,
//                 fit: BoxFit.cover,
//                 placeholder: (_, __) =>
//                 const Center(child: CircularProgressIndicator()),
//                 errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
//               )
//                   : Image.file(File(imagePath), fit: BoxFit.cover),
//             ),
//             if (!isLocked)
//               Positioned(
//                 right: 10,
//                 top: 10,
//                 child: Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(Icons.edit_rounded,
//                       color: Colors.white, size: 16),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // Empty Upload Placeholder
// // ─────────────────────────────────────────────────────────────
// class _EmptyUpload extends StatelessWidget {
//   final bool isDark;
//   final VoidCallback onTap;
//
//   const _EmptyUpload({required this.isDark, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: DottedBorder(
//         options: RectDottedBorderOptions(
//           dashPattern: const [6, 5],
//           strokeWidth: 1.5,
//           color: isDark ? AppThemeData.grey600 : AppThemeData.grey300,
//         ),
//         child: Container(
//           height: Responsive.height(20, context),
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: isDark
//                 ? AppThemeData.grey900.withOpacity(0.5)
//                 : AppThemeData.grey50,
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   color: AppThemeData.driverApp300.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(Icons.add_photo_alternate_rounded,
//                     color: AppThemeData.driverApp300, size: 26),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 "Tap to upload image".tr,
//                 style: TextStyle(
//                   color:
//                   isDark ? AppThemeData.grey300 : AppThemeData.grey700,
//                   fontFamily: AppThemeData.medium,
//                   fontSize: 15,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "JPEG or PNG",
//                 style: TextStyle(
//                   fontSize: 12,
//                   color:
//                   isDark ? AppThemeData.grey500 : AppThemeData.grey500,
//                   fontFamily: AppThemeData.regular,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // Selfie Tile
// // ─────────────────────────────────────────────────────────────
// class _SelfieTile extends StatelessWidget {
//   final DetailsUploadController controller;
//   final bool isDark;
//   final bool isLocked;
//   final BuildContext context;
//
//   const _SelfieTile({
//     required this.controller,
//     required this.isDark,
//     required this.isLocked,
//     required this.context,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final selfie = controller.selfieImage.value;
//     final hasSelfie = selfie.isNotEmpty;
//     final isUrl = Constant().hasValidUrl(selfie);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 4, bottom: 10),
//             child: Row(
//               children: [
//                 Icon(Icons.face_retouching_natural_rounded,
//                     size: 18, color: AppThemeData.driverApp300),
//                 const SizedBox(width: 6),
//                 Text(
//                   "Selfie / Profile Photo",
//                   style: TextStyle(
//                     color:
//                     isDark ? AppThemeData.grey200 : AppThemeData.grey800,
//                     fontFamily: AppThemeData.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           hasSelfie
//               ? GestureDetector(
//             onTap: isLocked
//                 ? null
//                 : () => _pickSelfie(context, controller),
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(60),
//                   child: SizedBox(
//                     width: 90,
//                     height: 90,
//                     child: isUrl
//                         ? CachedNetworkImage(
//                         imageUrl: selfie, fit: BoxFit.cover)
//                         : Image.file(File(selfie), fit: BoxFit.cover),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Selfie uploaded",
//                         style: TextStyle(
//                           fontFamily: AppThemeData.bold,
//                           fontSize: 14,
//                           color: isDark
//                               ? AppThemeData.grey100
//                               : AppThemeData.grey900,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       if (!isLocked)
//                         TextButton.icon(
//                           onPressed: () =>
//                               _pickSelfie(context, controller),
//                           icon: const Icon(Icons.refresh_rounded,
//                               size: 14),
//                           label: const Text("Retake"),
//                           style: TextButton.styleFrom(
//                             padding: EdgeInsets.zero,
//                             foregroundColor: AppThemeData.driverApp300,
//                             tapTargetSize:
//                             MaterialTapTargetSize.shrinkWrap,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           )
//               : GestureDetector(
//             onTap: () => _pickSelfie(context, controller),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 20),
//               decoration: BoxDecoration(
//                 color: isDark
//                     ? AppThemeData.grey900.withOpacity(0.5)
//                     : AppThemeData.grey50,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: isDark
//                       ? AppThemeData.grey700
//                       : AppThemeData.grey200,
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     width: 56,
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color:
//                       AppThemeData.driverApp300.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child:  Icon(Icons.camera_front_rounded,
//                         color: AppThemeData.driverApp300, size: 26),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Take a selfie",
//                     style: TextStyle(
//                       fontFamily: AppThemeData.medium,
//                       fontSize: 15,
//                       color: isDark
//                           ? AppThemeData.grey300
//                           : AppThemeData.grey700,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     "This will be used as your profile photo",
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: isDark
//                           ? AppThemeData.grey500
//                           : AppThemeData.grey500,
//                       fontFamily: AppThemeData.regular,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _pickSelfie(
//       BuildContext context, DetailsUploadController controller) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         final isDark =
//         Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
//         return Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "Upload Selfie".tr,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.bold,
//                   fontSize: 16,
//                   color:
//                   isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _SourceOption(
//                     icon: Icons.camera_front_rounded,
//                     label: "Camera",
//                     isDark: isDark,
//                     onTap: () => controller.pickSelfie(
//                         source: ImageSource.camera),
//                   ),
//                   _SourceOption(
//                     icon: Icons.photo_library_rounded,
//                     label: "Gallery",
//                     isDark: isDark,
//                     onTap: () => controller.pickSelfie(
//                         source: ImageSource.gallery),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // Aadhaar Section
// // ─────────────────────────────────────────────────────────────
// class _AadhaarSection extends StatelessWidget {
//   final DetailsUploadController controller;
//   final bool isDark;
//
//   const _AadhaarSection(
//       {required this.controller, required this.isDark});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Obx(() {
//         if (controller.aadhaarVerified.value) {
//           return _buildVerifiedCard();
//         }
//         if (controller.aadhaarOtpSent.value) {
//           return _buildOtpCard(context);
//         }
//         return _buildAadhaarInputCard(context);
//       }),
//     );
//   }
//
//   Widget _buildAadhaarInputCard(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: isDark ? AppThemeData.grey900 : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(Icons.credit_card_rounded,
//                     color: Colors.blue, size: 20),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 "Aadhaar Authentication",
//                 style: TextStyle(
//                   fontFamily: AppThemeData.bold,
//                   fontSize: 16,
//                   color:
//                   isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "Enter your 12-digit Aadhaar number to receive an OTP for verification.",
//             style: TextStyle(
//               fontSize: 13,
//               color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
//               fontFamily: AppThemeData.regular,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: controller.aadhaarController,
//             keyboardType: TextInputType.number,
//             maxLength: 12,
//             style: TextStyle(
//               color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//               fontFamily: AppThemeData.medium,
//               fontSize: 18,
//               letterSpacing: 2,
//             ),
//             decoration: InputDecoration(
//               counterText: "",
//               hintText: "XXXX XXXX XXXX",
//               hintStyle: TextStyle(
//                 color: isDark ? AppThemeData.grey600 : AppThemeData.grey400,
//                 letterSpacing: 2,
//               ),
//               prefixIcon: Icon(Icons.fingerprint_rounded,
//                   color: AppThemeData.driverApp300),
//               filled: true,
//               fillColor: isDark
//                   ? AppThemeData.grey800
//                   : AppThemeData.grey50,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                     color: AppThemeData.driverApp300, width: 1.5),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: controller.aadhaarLoading.value
//                   ? null
//                   : () => controller.sendAadhaarOtp(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppThemeData.driverApp300,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: controller.aadhaarLoading.value
//                   ? const SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(
//                     color: Colors.white, strokeWidth: 2),
//               )
//                   : const Text(
//                 "Send OTP",
//                 style: TextStyle(
//                     fontFamily: AppThemeData.medium, fontSize: 15),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOtpCard(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: isDark ? AppThemeData.grey900 : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(Icons.sms_rounded,
//                     color: Colors.orange, size: 20),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 "Enter OTP",
//                 style: TextStyle(
//                   fontFamily: AppThemeData.bold,
//                   fontSize: 16,
//                   color:
//                   isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             "OTP sent to mobile linked with your Aadhaar. Enter it below.",
//             style: TextStyle(
//               fontSize: 13,
//               color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
//               fontFamily: AppThemeData.regular,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: controller.otpController,
//             keyboardType: TextInputType.number,
//             maxLength: 6,
//             style: TextStyle(
//               color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//               fontFamily: AppThemeData.medium,
//               fontSize: 22,
//               letterSpacing: 6,
//             ),
//             decoration: InputDecoration(
//               counterText: "",
//               hintText: "• • • • • •",
//               hintStyle: TextStyle(
//                 color: isDark ? AppThemeData.grey600 : AppThemeData.grey400,
//                 letterSpacing: 4,
//               ),
//               prefixIcon:  Icon(Icons.lock_rounded,
//                   color: AppThemeData.driverApp300),
//               filled: true,
//               fillColor:
//               isDark ? AppThemeData.grey800 : AppThemeData.grey50,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                     color: AppThemeData.driverApp300, width: 1.5),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => controller.resetAadhaarFlow(),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12)),
//                     side: BorderSide(
//                         color: isDark
//                             ? AppThemeData.grey600
//                             : AppThemeData.grey300),
//                   ),
//                   child: Text(
//                     "Back",
//                     style: TextStyle(
//                       color: isDark
//                           ? AppThemeData.grey300
//                           : AppThemeData.grey700,
//                       fontFamily: AppThemeData.medium,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 flex: 2,
//                 child: ElevatedButton(
//                   onPressed: controller.aadhaarLoading.value
//                       ? null
//                       : () => controller.verifyAadhaarOtp(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppThemeData.driverApp300,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: controller.aadhaarLoading.value
//                       ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                         color: Colors.white, strokeWidth: 2),
//                   )
//                       : const Text(
//                     "Verify OTP",
//                     style: TextStyle(
//                         fontFamily: AppThemeData.medium, fontSize: 15),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVerifiedCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.green.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.green.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.15),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.verified_rounded,
//                 color: Colors.green, size: 26),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Aadhaar Verified!",
//                   style: TextStyle(
//                     fontFamily: AppThemeData.bold,
//                     fontSize: 15,
//                     color:
//                     isDark ? AppThemeData.grey100 : AppThemeData.grey900,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   "Your Aadhaar has been authenticated successfully.",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isDark
//                         ? AppThemeData.grey400
//                         : AppThemeData.grey600,
//                     fontFamily: AppThemeData.regular,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // Source Option (camera / gallery picker button)
// // ─────────────────────────────────────────────────────────────
// class _SourceOption extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isDark;
//   final VoidCallback onTap;
//
//   const _SourceOption({
//     required this.icon,
//     required this.label,
//     required this.isDark,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               color: AppThemeData.driverApp300.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Icon(icon, color: AppThemeData.driverApp300, size: 28),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontFamily: AppThemeData.medium,
//               fontSize: 13,
//               color: isDark ? AppThemeData.grey300 : AppThemeData.grey700,
//             ),
//           ),
//         ],
//       ),
//     );
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

// ─────────────────────────────────────────────────────────────────────────────
// Upload Screen
// ─────────────────────────────────────────────────────────────────────────────
class VerificationDetailsUploadScreen extends StatelessWidget {
  const VerificationDetailsUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    return GetX<DetailsUploadController>(
      init: DetailsUploadController(),
      builder: (controller) {
        final isSelfieOnly = controller.isSelfieOnly.value;
        final docStatus = controller.documents.value.status;
        // Doc is locked when already approved or in-review (but selfie is always re-uploadable)
        final isDocLocked =
            !isSelfieOnly && (docStatus == 'approved' || docStatus == 'uploaded');
        final showAadhaarOtp = !isSelfieOnly &&
            controller.isAadhaarDocument &&
            controller.isAadhaarOtpConfigured;
        final showDocImages = !isSelfieOnly &&
            (!controller.isAadhaarDocument ||
                !controller.isAadhaarOtpConfigured ||
                controller.aadhaarVerified.value);

        return Scaffold(
          backgroundColor:
          isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
          appBar: _buildAppBar(controller, isDark),
          body: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DocHeader(controller: controller, isDark: isDark),
              ),

              // ── Aadhaar OTP (only when backend keys are configured) ──
              if (showAadhaarOtp)
                SliverToBoxAdapter(
                  child: _AadhaarSection(
                      controller: controller, isDark: isDark),
                ),

              // ── Document photos (non-Aadhaar, or Aadhaar manual / after OTP) ──
              if (showDocImages) ...[
                if (controller.documentModel.value.frontSide == true)
                  SliverToBoxAdapter(
                    child: _ImageUploadTile(
                      label:
                      'Front Side of ${controller.documentModel.value.title}',
                      imagePath: controller.frontImage.value,
                      isDark: isDark,
                      isLocked: isDocLocked,
                      onTap: () => _showSourceSheet(
                          context, controller, 'front'),
                    ),
                  ),
                if (controller.documentModel.value.backSide == true)
                  SliverToBoxAdapter(
                    child: _ImageUploadTile(
                      label:
                      'Back Side of ${controller.documentModel.value.title}',
                      imagePath: controller.backImage.value,
                      isDark: isDark,
                      isLocked: isDocLocked,
                      onTap: () =>
                          _showSourceSheet(context, controller, 'back'),
                    ),
                  ),
              ],

              // ── Selfie ────────────────────────────────────────
              if (isSelfieOnly)
                SliverToBoxAdapter(
                  child: _SelfieTile(
                    controller: controller,
                    isDark: isDark,
                    isLocked: false, // selfie always re-uploadable
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // Hide submit button when doc is locked (approved/in-review)
          bottomNavigationBar: isDocLocked
              ? _LockedBanner(isDark: isDark, status: docStatus ?? '')
              : _SubmitButton(controller: controller, isDark: isDark),
        );
      },
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      DetailsUploadController controller, bool isDark) {
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
        controller.isSelfieOnly.value
            ? 'Selfie / Profile Photo'.tr
            : '${controller.documentModel.value.title}',
        style: TextStyle(
          color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
          fontFamily: AppThemeData.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── Bottom Sheet (camera / gallery) ────────────────────────────────
  static void _showSourceSheet(
      BuildContext context, DetailsUploadController controller, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final dark =
        Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
        return _SourceSheet(
          title: 'Select Image Source'.tr,
          isDark: dark,
          onCamera: () =>
              controller.pickFile(source: ImageSource.camera, type: type),
          onGallery: () =>
              controller.pickFile(source: ImageSource.gallery, type: type),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doc Header
// ─────────────────────────────────────────────────────────────────────────────
class _DocHeader extends StatelessWidget {
  final DetailsUploadController controller;
  final bool isDark;
  const _DocHeader({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isSelfieOnly = controller.isSelfieOnly.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSelfieOnly
                ? 'Upload Selfie / Profile Photo'.tr
                : '${'Upload'.tr} ${controller.documentModel.value.title}',
            style: TextStyle(
              color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
              fontFamily: AppThemeData.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSelfieOnly
                ? 'Upload a clear selfie. It will be used as your profile photo.'
                .tr
                : 'Upload a clear, valid document to verify your identity.'.tr,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit Button
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final DetailsUploadController controller;
  final bool isDark;
  const _SubmitButton({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => ElevatedButton(
              onPressed: controller.isUploading.value
                  ? null
                  : () => controller.onSubmitPressed(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.driverApp300,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: controller.isUploading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Upload Document'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.semiBold,
                      ),
                    ),
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked Banner (shown when doc already submitted/approved)
// ─────────────────────────────────────────────────────────────────────────────
class _LockedBanner extends StatelessWidget {
  final bool isDark;
  final String status;
  const _LockedBanner({required this.isDark, required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'approved';
    final color = isApproved ? Colors.green : AppThemeData.primary300;
    final icon = isApproved
        ? Icons.verified_rounded
        : Icons.hourglass_top_rounded;
    final label = isApproved ? 'Document Verified' : 'Under Review';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label.tr,
                style: TextStyle(
                  color: color,
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Upload Tile
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Image Preview (with edit overlay)
// ─────────────────────────────────────────────────────────────────────────────
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
                errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image),
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
            if (isLocked)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Upload Placeholder
// ─────────────────────────────────────────────────────────────────────────────
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
                'Tap to upload image'.tr,
                style: TextStyle(
                  color: isDark ? AppThemeData.grey300 : AppThemeData.grey700,
                  fontFamily: AppThemeData.medium,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'JPEG or PNG',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppThemeData.grey500 : AppThemeData.grey500,
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

// ─────────────────────────────────────────────────────────────────────────────
// Selfie Tile
// ─────────────────────────────────────────────────────────────────────────────
class _SelfieTile extends StatelessWidget {
  final DetailsUploadController controller;
  final bool isDark;
  final bool isLocked;

  const _SelfieTile({
    required this.controller,
    required this.isDark,
    required this.isLocked,
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
                  'Selfie / Profile Photo',
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
              ? _SelfiePreview(
            selfie: selfie,
            isUrl: isUrl,
            isDark: isDark,
            isLocked: isLocked,
            onRetake: () => _pickSelfie(context, controller),
          )
              : GestureDetector(
            onTap: () => _pickSelfie(context, controller),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                      AppThemeData.driverApp300.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_front_rounded,
                        color: AppThemeData.driverApp300, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Take a selfie',
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 15,
                      color: isDark
                          ? AppThemeData.grey300
                          : AppThemeData.grey700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This will be used as your profile photo',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final dark =
        Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
        return _SourceSheet(
          title: 'Upload Selfie'.tr,
          isDark: dark,
          onCamera: () =>
              controller.pickSelfie(source: ImageSource.camera),
          onGallery: () =>
              controller.pickSelfie(source: ImageSource.gallery),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selfie Preview Row
// ─────────────────────────────────────────────────────────────────────────────
class _SelfiePreview extends StatelessWidget {
  final String selfie;
  final bool isUrl;
  final bool isDark;
  final bool isLocked;
  final VoidCallback onRetake;

  const _SelfiePreview({
    required this.selfie,
    required this.isUrl,
    required this.isDark,
    required this.isLocked,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey900 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppThemeData.grey700 : AppThemeData.grey200,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: 72,
              height: 72,
              child: isUrl
                  ? CachedNetworkImage(
                  imageUrl: selfie, fit: BoxFit.cover)
                  : Image.file(File(selfie), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selfie uploaded',
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 15,
                    color:
                    isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Looking good! Tap retake to change.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    isDark ? AppThemeData.grey400 : AppThemeData.grey600,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
                if (!isLocked) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onRetake,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 14,
                            color: AppThemeData.driverApp300),
                        const SizedBox(width: 4),
                        Text(
                          'Retake',
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 13,
                            color: AppThemeData.driverApp300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 22),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aadhaar Section
// ─────────────────────────────────────────────────────────────────────────────
class _AadhaarSection extends StatelessWidget {
  final DetailsUploadController controller;
  final bool isDark;
  const _AadhaarSection({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        if (controller.aadhaarVerified.value) return _buildVerifiedCard();
        if (controller.aadhaarOtpSent.value) return _buildOtpCard();
        return _buildAadhaarInputCard();
      }),
    );
  }

  Widget _buildAadhaarInputCard() {
    return _AadhaarCard(
      isDark: isDark,
      icon: Icons.credit_card_rounded,
      iconColor: Colors.blue,
      title: 'Aadhaar Authentication',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your 12-digit Aadhaar number to receive an OTP.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
              fontFamily: AppThemeData.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _AadhaarTextField(
            controller: controller.aadhaarController,
            hintText: 'XXXX XXXX XXXX',
            icon: Icons.fingerprint_rounded,
            isDark: isDark,
            keyboardType: TextInputType.number,
            maxLength: 12,
            letterSpacing: 2,
            fontSize: 18,
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: 'Send OTP',
            isLoading: controller.aadhaarLoading.value,
            onPressed: controller.sendAadhaarOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return _AadhaarCard(
      isDark: isDark,
      icon: Icons.sms_rounded,
      iconColor: Colors.orange,
      title: 'Enter OTP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OTP sent to the mobile number linked with your Aadhaar.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
              fontFamily: AppThemeData.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _AadhaarTextField(
            controller: controller.otpController,
            hintText: '• • • • • •',
            icon: Icons.lock_rounded,
            isDark: isDark,
            keyboardType: TextInputType.number,
            maxLength: 6,
            letterSpacing: 6,
            fontSize: 22,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.resetAadhaarFlow,
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
                    'Back',
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
                child: _ActionButton(
                  label: 'Verify OTP',
                  isLoading: controller.aadhaarLoading.value,
                  onPressed: controller.verifyAadhaarOtp,
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
            child:
            const Icon(Icons.verified_rounded, color: Colors.green, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aadhaar Verified!',
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 15,
                    color:
                    isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your Aadhaar has been authenticated successfully.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    isDark ? AppThemeData.grey400 : AppThemeData.grey600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared Aadhaar card shell
// ─────────────────────────────────────────────────────────────────────────────
class _AadhaarCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _AadhaarCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable styled text field for Aadhaar/OTP
// ─────────────────────────────────────────────────────────────────────────────
class _AadhaarTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboardType;
  final int maxLength;
  final double letterSpacing;
  final double fontSize;

  const _AadhaarTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.isDark,
    required this.keyboardType,
    required this.maxLength,
    required this.letterSpacing,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(
        color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
        fontFamily: AppThemeData.medium,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? AppThemeData.grey600 : AppThemeData.grey400,
          letterSpacing: letterSpacing,
          fontSize: fontSize,
        ),
        prefixIcon: Icon(icon, color: AppThemeData.driverApp300),
        filled: true,
        fillColor: isDark ? AppThemeData.grey800 : AppThemeData.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: AppThemeData.driverApp300, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable primary action button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemeData.driverApp300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : Text(
          label,
          style: const TextStyle(
              fontFamily: AppThemeData.medium, fontSize: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Sheet (camera / gallery picker)
// ─────────────────────────────────────────────────────────────────────────────
class _SourceSheet extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourceSheet({
    required this.title,
    required this.isDark,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
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
            title,
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
                label: 'Camera',
                isDark: isDark,
                onTap: onCamera,
              ),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                isDark: isDark,
                onTap: onGallery,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Option (icon + label button)
// ─────────────────────────────────────────────────────────────────────────────
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