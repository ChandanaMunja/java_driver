import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jippydriver_driver/app/withdraw_method_setup_screens/bank_details_screen.dart';
import 'package:jippydriver_driver/controllers/withdraw_method_setup_controller.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';

class WithdrawMethodSetupScreen extends StatelessWidget {
  const WithdrawMethodSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<WithdrawMethodSetupController>(
      init: WithdrawMethodSetupController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Scaffold(
            backgroundColor: _bgColor(themeChange),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: _bgColor(themeChange),
          appBar: _buildAppBar(themeChange),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _WalletBalanceCard(themeChange: themeChange),
                // const SizedBox(height: 20),
                _sectionLabel("Payout Methods", themeChange),
                const SizedBox(height: 8),
                _BankTransferCard(
                  controller: controller,
                  themeChange: themeChange,
                  context: context,
                ),
                const SizedBox(height: 10),
                _ComingSoonMethodCard(
                  label: "PayPal",
                  iconAsset: "assets/images/paypal.png",
                  themeChange: themeChange,
                ),
                const SizedBox(height: 10),
                _ComingSoonMethodCard(
                  label: "Stripe Connect",
                  iconAsset: "assets/images/stripe.png",
                  themeChange: themeChange,
                ),
                const SizedBox(height: 10),
                _ComingSoonMethodCard(
                  label: "FlutterWave",
                  iconAsset: "assets/images/flutterwave.png",
                  themeChange: themeChange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(DarkThemeProvider themeChange) {
    return AppBar(
      backgroundColor: _bgColor(themeChange),
      elevation: 0,
      centerTitle: false,
      title: Text(
        "Payout Setup".tr,
        style: TextStyle(
          color: themeChange.getThem()
              ? AppThemeData.grey50
              : AppThemeData.grey900,
          fontSize: 18,
          fontFamily: AppThemeData.medium,
        ),
      ),
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

// ─── Wallet Balance Card ──────────────────────────────────────────────────────

// class _WalletBalanceCard extends StatelessWidget {
//   final DarkThemeProvider themeChange;
//   const _WalletBalanceCard({required this.themeChange});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF185FA5), Color(0xFF378ADD)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Available Balance".tr,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 12,
//               letterSpacing: 0.5,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             Constant.amountShow(
//               amount: ,
//             ),            style: const TextStyle(color: Colors.white, fontSize: 28),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.18),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   "Withdraw".tr,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }

// ─── Bank Transfer Card ───────────────────────────────────────────────────────

class _BankTransferCard extends StatelessWidget {
  final WithdrawMethodSetupController controller;
  final DarkThemeProvider themeChange;
  final BuildContext context;

  const _BankTransferCard({
    required this.controller,
    required this.themeChange,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDone = controller.isBankDetailsAdded.value;
    return _MethodCard(
      themeChange: themeChange,
      isActive: isDone,
      child: Column(
        children: [
          Row(
            children: [
              _MethodIcon(
                themeChange: themeChange,
                child: SvgPicture.asset(
                  "assets/icons/ic_building_four.svg",
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isDone ? AppThemeData.primary300 : AppThemeData.grey500,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bank Transfer".tr,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontSize: 15,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Direct bank deposit".tr,
                      style: TextStyle(
                        color: AppThemeData.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                _StatusBadge(label: "Done", isSuccess: true)
              else
                _StatusBadge(label: "Pending", isSuccess: false),
              const SizedBox(width: 8),
              _EditButton(
                themeChange: themeChange,
                onTap: () => Get.to(const BankDetailsScreen()),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: themeChange.getThem()
                  ? AppThemeData.grey700
                  : AppThemeData.grey200,
              height: 1,
            ),
          ),
          Row(
            children: [
              if (isDone) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF639922),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${controller.userBankDetails.value.bankName} · ••••${controller.userBankDetails.value.accountNumber.length > 4 ? controller.userBankDetails.value.accountNumber.substring(controller.userBankDetails.value.accountNumber.length - 4) : controller.userBankDetails.value.accountNumber}",
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey400
                          : AppThemeData.grey600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                Text(
                  "Setup required".tr,
                  style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey400
                        : AppThemeData.grey600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Get.to(const BankDetailsScreen()),
                  child: Text(
                    "Set up now".tr,
                    style: const TextStyle(
                      color: AppThemeData.primary300,
                      fontSize: 13,
                      fontFamily: AppThemeData.medium,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Coming Soon Card ─────────────────────────────────────────────────────────

class _ComingSoonMethodCard extends StatelessWidget {
  final String label;
  final String iconAsset;
  final DarkThemeProvider themeChange;

  const _ComingSoonMethodCard({
    required this.label,
    required this.iconAsset,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: _MethodCard(
        themeChange: themeChange,
        isActive: false,
        child: Row(
          children: [
            _MethodIcon(
              themeChange: themeChange,
              child: Image.asset(iconAsset, width: 22, height: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey50
                          : AppThemeData.grey900,
                      fontSize: 15,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Coming soon".tr,
                    style: TextStyle(
                      color: AppThemeData.grey400,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppThemeData.grey800
                    : AppThemeData.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Not available".tr,
                style: TextStyle(
                  color: AppThemeData.grey500,
                  fontSize: 11,
                  fontFamily: AppThemeData.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Small Widgets ─────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final DarkThemeProvider themeChange;
  final Widget child;
  final bool isActive;

  const _MethodCard({
    required this.themeChange,
    required this.child,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppThemeData.grey900
            : AppThemeData.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppThemeData.primary300
              : themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey200,
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _MethodIcon extends StatelessWidget {
  final DarkThemeProvider themeChange;
  final Widget child;

  const _MethodIcon({required this.themeChange, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppThemeData.grey800
            : AppThemeData.grey100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: themeChange.getThem()
              ? AppThemeData.grey700
              : AppThemeData.grey200,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isSuccess;

  const _StatusBadge({required this.label, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFFEAF3DE)
            : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSuccess
              ? const Color(0xFF3B6D11)
              : const Color(0xFF854F0B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final DarkThemeProvider themeChange;
  final VoidCallback onTap;

  const _EditButton({required this.themeChange, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: themeChange.getThem()
                ? AppThemeData.grey700
                : AppThemeData.grey200,
            width: 0.5,
          ),
          color: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey100,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SvgPicture.asset("assets/icons/ic_edit_coupon.svg"),
        ),
      ),
    );
  }
}