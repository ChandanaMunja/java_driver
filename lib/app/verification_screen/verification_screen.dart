// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/controllers/verification_controller.dart';
// import 'package:jippydriver_driver/models/document_model.dart';
// import 'package:jippydriver_driver/models/driver_document_model.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import 'verification_details_upload_screen.dart';
//
// class VerificationScreen extends StatelessWidget {
//   const VerificationScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return GetBuilder<VerificationController>(
//         init: VerificationController(),
//         builder: (controller) {
//           return Scaffold(
//             backgroundColor: themeChange.getThem()
//                 ? AppThemeData.surfaceDark
//                 : AppThemeData.surface,
//             body: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: controller.isLoading.value
//                   ? Constant.loader()
//                   : Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Document Verification".tr,
//                           style: TextStyle(
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey100
//                                   : AppThemeData.grey800,
//                               fontFamily: AppThemeData.bold,
//                               fontSize: 22),
//                         ),
//                         const SizedBox(
//                           height: 5,
//                         ),
//                         Text(
//                           "Upload your ID Proof to complete the verification process and ensure compliance."
//                               .tr,
//                           style: TextStyle(
//                               fontSize: 14,
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey200
//                                   : AppThemeData.grey700,
//                               fontFamily: AppThemeData.regular),
//                         ),
//                         const SizedBox(
//                           height: 40,
//                         ),
//                         Container(
//                           decoration: ShapeDecoration(
//                             color: themeChange.getThem()
//                                 ? AppThemeData.grey900
//                                 : AppThemeData.grey50,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 20),
//                             child: ListView.separated(
//                               itemCount: controller.documentList.length,
//                               shrinkWrap: true,
//                               padding: EdgeInsets.zero,
//                               itemBuilder: (context, index) {
//                                 DocumentModel documentModel =
//                                     controller.documentList[index];
//                                 Documents documents = Documents();
//                                 var contain = controller.driverDocumentList
//                                     .where((element) =>
//                                         element.documentId == documentModel.id);
//                                 if (contain.isNotEmpty) {
//                                   documents = controller.driverDocumentList
//                                       .firstWhere((itemToCheck) =>
//                                           itemToCheck.documentId ==
//                                           documentModel.id);
//                                 }
//                                 return InkWell(
//                                   onTap: () {
//                                     Get.to(const VerificationDetailsUploadScreen(),
//                                             arguments: {
//                                           'documentModel': documentModel
//                                         })!
//                                         .then(
//                                       (value) {
//                                         if (value == true) {
//                                           controller.getDocument();
//                                         }
//                                       },
//                                     );
//                                   },
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     children: [
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "${documentModel.title}",
//                                               style: TextStyle(
//                                                 color: themeChange.getThem()
//                                                     ? AppThemeData.grey100
//                                                     : AppThemeData.grey800,
//                                                 fontFamily: AppThemeData.bold,
//                                                 fontSize: 16,
//                                               ),
//                                             ),
//                                             const SizedBox(
//                                               height: 5,
//                                             ),
//                                             Text(
//                                               "${documentModel.frontSide == true ? "Front" : ""} ${documentModel.backSide == true ? "And Back" : ""} ${'Photo'.tr}",
//                                               style: TextStyle(
//                                                 color: themeChange.getThem()
//                                                     ? AppThemeData.grey300
//                                                     : AppThemeData.grey600,
//                                                 fontFamily:
//                                                     AppThemeData.regular,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 10, vertical: 6),
//                                         child: Text(
//                                           documents.status == "approved"
//                                               ? "Verified".tr
//                                               : documents.status == "rejected"
//                                                   ? "Rejected".tr
//                                                   : documents.status ==
//                                                           "uploaded"
//                                                       ? "Uploaded".tr
//                                                       : "Pending".tr,
//                                           style: TextStyle(
//                                               color:
//                                                   documents.status == "approved"
//                                                       ? Colors.green
//                                                       : documents.status ==
//                                                               "rejected"
//                                                           ? Colors.red
//                                                           : documents.status ==
//                                                                   "uploaded"
//                                                               ? AppThemeData
//                                                                   .primary300
//                                                               : Colors.orange,
//                                               fontFamily: AppThemeData.medium,
//                                               fontSize: 16),
//                                         ),
//                                       ),
//                                       const Icon(
//                                         Icons.arrow_forward_ios_rounded,
//                                         size: 20,
//                                       )
//                                     ],
//                                   ),
//                                 );
//                               },
//                               separatorBuilder:
//                                   (BuildContext context, int index) {
//                                 return const Padding(
//                                   padding: EdgeInsets.symmetric(vertical: 10),
//                                   child: Divider(),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           );
//         });
//   }
// }



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/verification_controller.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'verification_details_upload_screen.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    return GetBuilder<VerificationController>(
      init: VerificationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor:
          isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
          body: SafeArea(
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildProgressBar(controller, isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildMandatoryIdentityFields(controller, isDark),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final hasSelfie =
                            (Constant.userModel?.profilePictureURL ?? "")
                                .trim()
                                .isNotEmpty;
                        if (index == controller.documentList.length) {
                          return _DocumentCard(
                            documentModel: DocumentModel(
                              title: "Selfie / Profile Photo",
                              frontSide: true,
                              backSide: false,
                            ),
                            documents: Documents(
                              status: hasSelfie ? "uploaded" : "pending",
                            ),
                            isDark: isDark,
                            onTap: () {
                              if (!_validateMandatoryFields(controller)) {
                                return;
                              }
                              Get.to(
                                const VerificationDetailsUploadScreen(),
                                arguments: {
                                  'selfieOnly': true,
                                  'aadhaarNumber':
                                      controller.aadhaarNumberController.text.trim(),
                                  'drivingLicenseNumber':
                                      controller.drivingLicenseController.text.trim(),
                                },
                                transition: Transition.cupertino,
                              )?.then((value) {
                                if (value == true) {
                                  controller.getDocument();
                                }
                              });
                            },
                          );
                        }
                        final doc = controller.documentList[index];
                        final uploadedDoc = _findDocument(
                            controller.driverDocumentList.toList(), doc);
                        return _DocumentCard(
                          documentModel: doc,
                          documents: uploadedDoc,
                          isDark: isDark,
                          onTap: () {
                            if (!_validateMandatoryFields(controller)) {
                              return;
                            }
                            Get.to(
                              const VerificationDetailsUploadScreen(),
                              arguments: {
                                'documentModel': doc,
                                'aadhaarNumber':
                                    controller.aadhaarNumberController.text.trim(),
                                'drivingLicenseNumber':
                                    controller.drivingLicenseController.text.trim(),
                              },
                              transition: Transition.cupertino,
                            )?.then((value) {
                              if (value == true) {
                                controller.getDocument();
                              }
                            });
                          },
                        );
                      },
                      childCount: controller.documentList.length + 1,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 24)),
              ],
            ),
          ),
          bottomNavigationBar: controller.isLoading.value
              ? const SizedBox.shrink()
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ElevatedButton(
                      onPressed: controller.isSubmittingIdentity.value
                          ? null
                          : () async {
                              final ok = await controller.submitIdentityDetails();
                              if (ok) {
                                Get.to(() => const _VerificationPendingScreen());
                              } else {
                                ShowToastDialog.showToast(
                                  "Failed to submit details. Please try again.",
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppThemeData.driverApp300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSubmittingIdentity.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Submit Details".tr,
                              style: const TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Documents _findDocument(List<Documents> list, DocumentModel doc) {
    final match = list.where((e) => e.documentId == doc.id);
    return match.isNotEmpty ? match.first : Documents();
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppThemeData.driverApp300.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.verified_user_rounded,
                color: AppThemeData.driverApp300, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            "Document Verification".tr,
            style: TextStyle(
              color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
              fontFamily: AppThemeData.bold,
              fontSize: 28,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Complete your profile by uploading the required identity documents below."
                .tr,
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

  Widget _buildProgressBar(VerificationController controller, bool isDark) {
    // Selfie is optional and not part of required verification count.
    final total = controller.documentList.length;
    if (total == 0) return const SizedBox();

    final approved = controller.driverDocumentList
        .where((d) => d.status == "approved")
        .length;
    final progress = approved / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$approved of $total verified",
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.medium,
                  color: isDark ? AppThemeData.grey300 : AppThemeData.grey600,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.bold,
                  color: AppThemeData.driverApp300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppThemeData.grey800
                  : AppThemeData.grey200,
              valueColor:
              AlwaysStoppedAnimation<Color>(AppThemeData.driverApp300),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  bool _validateMandatoryFields(VerificationController controller) {
    final aadhaar = controller.aadhaarNumberController.text.trim();
    final dl = controller.drivingLicenseController.text.trim();
    if (aadhaar.isEmpty) {
      ShowToastDialog.showToast("Aadhaar number is required".tr);
      return false;
    }
    if (dl.isEmpty) {
      ShowToastDialog.showToast("Driving license number is required".tr);
      return false;
    }
    return true;
  }

  Widget _buildMandatoryIdentityFields(
      VerificationController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppThemeData.grey700 : AppThemeData.grey200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Required Details".tr,
              style: TextStyle(
                color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                fontFamily: AppThemeData.semiBold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.aadhaarNumberController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Aadhaar Number *".tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.drivingLicenseController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Driving License Number *".tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationPendingScreen extends StatelessWidget {
  const _VerificationPendingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 56,
                  color: AppThemeData.primary300,
                ),
                const SizedBox(height: 16),
                Text(
                  "Please wait until approval".tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: AppThemeData.semiBold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your verification details were submitted. We will notify you once approved."
                      .tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.regular,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel documentModel;
  final Documents documents;
  final bool isDark;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.documentModel,
    required this.documents,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = documents.status ?? "";
    final statusConfig = _statusConfig(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusConfig['borderColor'] as Color,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.grey.shade200)
                      .withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (statusConfig['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusConfig['icon'] as IconData,
                      color: statusConfig['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${documentModel.title}",
                          style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey100
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _sideLabel(),
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
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (statusConfig['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusConfig['label'] as String,
                      style: TextStyle(
                        color: statusConfig['color'] as Color,
                        fontFamily: AppThemeData.medium,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppThemeData.grey500 : AppThemeData.grey400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sideLabel() {
    final parts = <String>[];
    if (documentModel.frontSide == true) parts.add("Front");
    if (documentModel.backSide == true) parts.add("Back");
    return "${parts.join(' & ')} Photo";
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case "approved":
        return {
          'label': "Verified",
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
          'borderColor': Colors.green.withOpacity(0.3),
        };
      case "rejected":
        return {
          'label': "Rejected",
          'color': Colors.red,
          'icon': Icons.cancel_rounded,
          'borderColor': Colors.red.withOpacity(0.3),
        };
      case "uploaded":
        return {
          'label': "In Review",
          'color': AppThemeData.primary300,
          'icon': Icons.hourglass_top_rounded,
          'borderColor': AppThemeData.primary300.withOpacity(0.3),
        };
      default:
        return {
          'label': "Pending",
          'color': Colors.orange,
          'icon': Icons.upload_file_rounded,
          'borderColor': Colors.orange.withOpacity(0.2),
        };
    }
  }
}