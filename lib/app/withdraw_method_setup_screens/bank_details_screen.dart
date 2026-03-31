import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/bank_details_controller.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/themes/text_field_widget.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<BankDetailsController>(
      init: BankDetailsController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Scaffold(
            backgroundColor: _bgColor(themeChange),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: _bgColor(themeChange),
          appBar: AppBar(
            backgroundColor: _bgColor(themeChange),
            elevation: 0,
            centerTitle: false,
            title: Text(
              "Bank Setup".tr,
              style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
                fontSize: 18,
                fontFamily: AppThemeData.medium,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoBanner(themeChange: themeChange),
                const SizedBox(height: 20),
                _sectionLabel("Bank Information", themeChange),
                const SizedBox(height: 10),
                _FormCard(
                  themeChange: themeChange,
                  child: Column(
                    children: [
                      TextFieldWidget(
                        title: "Bank Name".tr,
                        controller: controller.bankNameController.value,
                        hintText: "e.g. HDFC Bank".tr,
                      ),
                      TextFieldWidget(
                        title: "Branch Name".tr,
                        controller: controller.branchNameController.value,
                        hintText: "e.g. Nellore Main Branch".tr,
                      ),
                      TextFieldWidget(
                        title: "Account Holder Name".tr,
                        controller: controller.holderNameController.value,
                        hintText: "Full name as on account".tr,
                      ),
                      TextFieldWidget(
                        title: "Account Number".tr,
                        controller: controller.accountNoController.value,
                        hintText: "Enter account number".tr,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      TextFieldWidget(
                        title: "IFSC / Routing / Other Info".tr,
                        controller: controller.otherInfoController.value,
                        hintText: "e.g. HDFC0001234".tr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: _SaveButton(
            controller: controller,
            themeChange: themeChange,
            context: context,
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label, DarkThemeProvider themeChange) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: themeChange.getThem()
            ? AppThemeData.grey500
            : AppThemeData.grey400,
        fontSize: 11,
        letterSpacing: 0.8,
        fontFamily: AppThemeData.medium,
      ),
    );
  }

  Color _bgColor(DarkThemeProvider themeChange) =>
      themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface;
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final DarkThemeProvider themeChange;
  const _InfoBanner({required this.themeChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? const Color(0xFF0C447C).withOpacity(0.25)
            : const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF85B7EB).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFF185FA5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your bank details are encrypted and used only for payouts."
                  .tr,
              style: TextStyle(
                color: themeChange.getThem()
                    ? const Color(0xFFB5D4F4)
                    : const Color(0xFF185FA5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form Card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final DarkThemeProvider themeChange;
  final Widget child;

  const _FormCard({required this.themeChange, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppThemeData.grey900
            : AppThemeData.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey200,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final BankDetailsController controller;
  final DarkThemeProvider themeChange;
  final BuildContext context;

  const _SaveButton({
    required this.controller,
    required this.themeChange,
    required this.context,
  });

  void _validate() {
    if (controller.bankNameController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter bank name".tr);
    } else if (controller.branchNameController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter branch name".tr);
    } else if (controller.holderNameController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter holder name".tr);
    } else if (controller.accountNoController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter account number".tr);
    } else {
      controller.saveBank();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: themeChange.getThem()
            ? AppThemeData.surfaceDark
            : AppThemeData.surface,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: InkWell(
          onTap: _validate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: Responsive.width(100, context),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppThemeData.driverApp300,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "Save Details".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: AppThemeData.medium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}