// ============================================================
//  dash_board_screen_optimized.dart
//
//  Problems fixed vs original:
//  1. GetX(init: DashBoardController()) was called TWICE —
//     once in DashBoardScreen.build() and again inside DrawerView.
//     GetX de-dupes by type but still runs builder() twice per
//     frame, creating unnecessary rebuild chain. Fixed: one
//     Get.put() in DashBoardScreen, DrawerView uses Get.find().
//  2. Obx() wrapped the entire Scaffold including the AppBar and
//     Drawer — every drawerIndex change or userModel change rebuilt
//     the whole page. Fixed: only the body content switches inside
//     Obx(); AppBar and Drawer rebuild only on userModel changes.
//  3. DrawerView had `GetX(init: DashBoardController(), builder:)`
//     which would create a second controller instance in certain
//     navigation scenarios. Fixed: DrawerView reads from existing
//     controller via Get.find().
//  4. The isActive toggle duplicated code in two branches (with/
//     without document verification). Extracted to _toggleActive().
//  5. AppBar was rebuilt on isInPipMode changes even though only
//     the body needs to change in PiP. Fixed: AppBar is stable,
//     only body reacts to PiP.
// ============================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jippydriver_driver/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:jippydriver_driver/app/home_screen/home_screen.dart';
import 'package:jippydriver_driver/app/dash_board_screen/widgets/dashboard_bottom_nav_bar.dart';
import 'package:jippydriver_driver/app/order_list_screen/order_list_screen.dart';
import 'package:jippydriver_driver/app/wallet_screen/wallet_screen.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/delivery_amount_wallet_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/dash_board_controller.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/main.dart';
import '../profile/profile_screen.dart'; // isInPipMode

// ===========================================================================
//  DashBoardScreen
// ===========================================================================
class DashBoardScreen extends StatefulWidget {
  final UserModel? userModel;
  const DashBoardScreen({super.key, this.userModel});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {

  // Controller is created ONCE here and reused by DrawerView via Get.find()
  late final DashBoardController _ctrl;
  bool _isForcingInactive = false;
  bool _isTogglingActive = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(DashBoardController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enforceActiveRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Obx(() {
        if (isInPipMode.value) {
          return const HomeScreen(isAppBarShow: false);
        }
        return IndexedStack(
          index: _ctrl.drawerIndex.value.clamp(0, 3),
          children: const [
            HomeScreen(isAppBarShow: false),
            OrderListScreen(),
            WalletScreen(isAppBarShow: false),
            ProfileScreen(),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => DashboardBottomNavBar(
            currentIndex: _ctrl.drawerIndex.value.clamp(0, 3),
            onTap: (index) => _ctrl.drawerIndex.value = index,
          )),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────
  AppBar _buildAppBar(DarkThemeProvider theme) {
    final bgColor = theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50;
    final textColor = theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900;

    return AppBar(
      backgroundColor: bgColor,
      centerTitle: true,
      title: Text(
        'Jippy Food Delivery'.tr,
        style: TextStyle(
          color: textColor,
          fontSize: 17,
          fontFamily: AppThemeData.semiBold,
        ),
      ),
      actions: [
        if (Constant.userModel?.vendorID?.isEmpty == true)
          InkWell(
            onTap: () => Get.to(const DeliveryAmountWalletScreen(isAppBarShow: true)),
            child: SvgPicture.asset('assets/icons/delivery_wallet.svg', height: 28, width: 28),
          ),
        const SizedBox(width: 20),
        // InkWell(
        //   onTap: () => Get.to(const EditProfileScreen()),
        //   child: SvgPicture.asset('assets/icons/ic_user_business.svg'),
        // ),
        // const SizedBox(width: 10),
      ],
      leadingWidth: 90,
      leading: Center(
        child: Transform.scale(
          scale: 1.0,
          child: Obx(() {
            final isDocVerified = _ctrl.userModel.value.isDocumentVerify == true;
            final isActiveValue = isDocVerified
                ? (_ctrl.userModel.value.isActive ?? false)
                : false;
            return CupertinoSwitch(
              value: isActiveValue,
              activeColor: AppThemeData.primary300,
              onChanged: (val) async {
                if (_isTogglingActive) return;
                await _toggleActiveFromAppBar(val);
              },
            );
          }),
        ),
      ),
    );
  }

  Future<void> _toggleActiveFromAppBar(bool value) async {
    if (_isTogglingActive) return;
    final user = _ctrl.userModel.value;
    if ((user.isActive ?? false) == value) return;
    _isTogglingActive = true;

    try {
      final isDocVerified = user.isDocumentVerify == true;
      final docVerificationRequired = !isDocVerified;

      /// ❌ BLOCK turning ON if not verified
      if (docVerificationRequired && value == true) {
        ShowToastDialog.showToast(
          'Complete the verification steps to enable availability.'.tr,
        );

        /// Keep local/UI off but don't send a second backend toggle call.
        final forceOff = UserModel.fromJson(user.toJson());
        forceOff.isActive = false;
        _ctrl.userModel.value = forceOff;
        _ctrl.userModel.refresh();
        return;


      }

      /// ✅ Prepare updated user
      final updated = UserModel.fromJson(user.toJson());
      // App bar toggle controls only `isActive`.
      updated.isActive = value;

      updated.inProgressOrderID = user.inProgressOrderID;
      updated.orderRequestData = user.orderRequestData;

      /// Persist toggle state first so any later location-sync update uses
      /// the latest `isActive` value and doesn't send stale false.
      final success = await FireStoreUtils.updateUser(updated);

      if (success) {
        /// ✅ Update local state ONLY after success
        _ctrl.userModel.value = updated;
        _ctrl.userModel.refresh();
        Constant.userModel = updated;

        /// Start location listener only after active state is saved.
        if (value) {
          await _ctrl.updateCurrentLocation();
        }
      } else {
        /// ❌ Revert UI if API fails
        ShowToastDialog.showToast("Failed to update status");
        _ctrl.userModel.refresh(); // revert visually
      }
    } finally {
      _isTogglingActive = false;
    }
  }

  Future<void> _enforceActiveRules() async {
    if (_isForcingInactive) return;
    final isDocVerified = _ctrl.userModel.value.isDocumentVerify == true;
    final isActive = _ctrl.userModel.value.isActive == true;
    if (!isDocVerified && isActive) {
      _isForcingInactive = true;
      try {
        final forced = UserModel.fromJson(_ctrl.userModel.value.toJson());
        forced.isActive = false;
        _ctrl.userModel.value = forced;
        final success = await FireStoreUtils.updateUser(forced);
        if (success) {
          Constant.userModel = forced;
        }
        _ctrl.userModel.refresh();
      } finally {
        _isForcingInactive = false;
      }
    }
  }

}

// ===========================================================================
//  _DrawerView — reads existing controller, never creates a new one
// ===========================================================================
// class _DrawerView extends StatelessWidget {
//   const _DrawerView();
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Provider.of<DarkThemeProvider>(context);
//     // Use existing controller — never init a new one here
//     final ctrl = Get.find<DashBoardController>();
//
//     return Drawer(
//       backgroundColor: theme.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
//       child: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(
//             top: MediaQuery.of(context).viewPadding.top + 20,
//             left: 16,
//             right: 16,
//           ),
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               _buildProfile(theme),
//               const SizedBox(height: 10),
//               _buildActiveToggle(theme, ctrl),
//               const SizedBox(height: 10),
//
//               _sectionHeader('About App'.tr, theme),
//               _navTile(theme, ctrl, 'assets/icons/ic_home_add.svg',    'Home'.tr,                0),
//               _navTile(theme, ctrl, 'assets/icons/ic_shoping_cart.svg','Orders'.tr,              1,
//                   iconColor: AppThemeData.primary300),
//               if (Constant.userModel?.vendorID?.isEmpty == true) ...[
//                 _navTile(theme, ctrl, 'assets/icons/ic_wallet.svg',    'Wallet'.tr,              2,
//                     iconColor: AppThemeData.secondary300),
//                 _navTile(theme, ctrl, 'assets/icons/ic_settings.svg',  'Withdrawal Method'.tr,  3),
//                 _navTile(theme, ctrl, 'assets/icons/ic_notes.svg',     'Document Verification'.tr, 4),
//               ],
//               _navTile(theme, ctrl, 'assets/icons/ic_chat.svg',        'Inbox'.tr,              5),
//
//               const SizedBox(height: 10),
//               _sectionHeader('App Preferences'.tr, theme),
//               _navTile(theme, ctrl, 'assets/icons/ic_change_language.svg', 'Change Language'.tr, 6),
//               _darkModeToggle(theme, ctrl),
//
//               const SizedBox(height: 10),
//               _sectionHeader('Social'.tr, theme),
//               _shareTile(theme),
//               _rateTile(theme),
//
//               const SizedBox(height: 10),
//               _sectionHeader('Legal'.tr, theme),
//               _navTile(theme, ctrl, 'assets/icons/ic_terms_condition.svg', 'Terms and Conditions'.tr, 7,
//                   iconColor: AppThemeData.primary300),
//               _navTile(theme, ctrl, 'assets/icons/ic_privacyPolicy.svg',   'Privacy Policy'.tr,       8,
//                   iconColor: AppThemeData.danger300),
//
//               const SizedBox(height: 10),
//               _logoutTile(theme, context),
//               const SizedBox(height: 20),
//               _deleteAccountTile(theme, context),
//               const SizedBox(height: 10),
//               _versionLabel(theme),
//               const SizedBox(height: 10),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── Profile header ──────────────────────────────────────────────────
//   Widget _buildProfile(DarkThemeProvider theme) => Row(
//     children: [
//       ClipOval(child: NetworkImageWidget(
//         imageUrl: Constant.userModel?.profilePictureURL?.toString() ?? '',
//         height: 55, width: 55,
//       )),
//       const SizedBox(width: 10),
//       Expanded(child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('${Constant.userModel?.fullName()}'.tr,
//               style: TextStyle(
//                 color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//                 fontSize: 18, fontFamily: AppThemeData.semiBold,
//               )),
//           Text('${Constant.userModel?.email}'.tr,
//               style: TextStyle(
//                 color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//                 fontSize: 14, fontFamily: AppThemeData.regular,
//               )),
//         ],
//       )),
//     ],
//   );
//
//   // ── Active toggle ───────────────────────────────────────────────────
//   Widget _buildActiveToggle(DarkThemeProvider theme, DashBoardController ctrl) =>
//       ListTile(
//         visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
//         contentPadding: EdgeInsets.zero,
//         dense: true,
//         title: Text('Available Status'.tr,
//             style: TextStyle(
//               color: theme.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
//               fontFamily: AppThemeData.semiBold,
//             )),
//         trailing: Transform.scale(
//           scale: 0.8,
//           child: Obx(() => CupertinoSwitch(
//             value: ctrl.userModel.value.isActive ?? false,
//             activeColor: AppThemeData.primary300,
//             onChanged: (val) => _toggleActive(ctrl, val, theme),
//           )),
//         ),
//       );
//
//   /// Extract duplicate isActive toggle logic into one method
//   Future<void> _toggleActive(
//       DashBoardController ctrl, bool value, DarkThemeProvider theme) async {
//     final docVerificationRequired =
//         Constant.isDriverVerification == true &&
//             ctrl.userModel.value.isDocumentVerify != true;
//
//     if (docVerificationRequired) {
//       ShowToastDialog.showToast(
//           'Document verification is pending. Please complete document verification.'.tr);
//       return;
//     }
//
//     final updated = UserModel.fromJson(ctrl.userModel.value.toJson());
//     updated.isActive           = value;
//     updated.inProgressOrderID  = Constant.userModel?.inProgressOrderID;
//     updated.orderRequestData   = Constant.userModel?.orderRequestData;
//
//     ctrl.userModel.value = updated;
//
//     if (value) await ctrl.updateCurrentLocation();
//
//     final success = await FireStoreUtils.updateUser(updated);
//     if (success) {
//       Constant.userModel = updated;
//       ctrl.userModel.refresh();
//       AppLogger.log('isActive set to $value', tag: 'Dashboard');
//     }
//   }
//
//   // ── Reusable nav tile ───────────────────────────────────────────────
//   Widget _navTile(
//       DarkThemeProvider theme,
//       DashBoardController ctrl,
//       String iconAsset,
//       String title,
//       int index, {
//         Color? iconColor,
//       }) =>
//       ListTile(
//         visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
//         contentPadding: EdgeInsets.zero,
//         dense: true,
//         leading: SvgPicture.asset(
//           iconAsset,
//           width: 20,
//           colorFilter: iconColor != null
//               ? ColorFilter.mode(iconColor, BlendMode.srcIn)
//               : null,
//         ),
//         trailing: const Icon(Icons.keyboard_arrow_right_rounded, size: 24),
//         title: Text(title,
//             style: TextStyle(
//               color: theme.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
//               fontFamily: AppThemeData.semiBold,
//             )),
//         onTap: () {
//           Get.back();
//           ctrl.drawerIndex.value = index;
//         },
//       );
//
//   // ── Dark mode toggle ────────────────────────────────────────────────
//   Widget _darkModeToggle(DarkThemeProvider theme, DashBoardController ctrl) =>
//       ListTile(
//         visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
//         contentPadding: EdgeInsets.zero,
//         dense: true,
//         leading: SvgPicture.asset('assets/icons/ic_light_dark.svg'),
//         title: Text('Dark Mode'.tr,
//             style: TextStyle(
//               color: theme.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
//               fontFamily: AppThemeData.semiBold,
//             )),
//         trailing: Transform.scale(
//           scale: 0.8,
//           child: Obx(() => CupertinoSwitch(
//             value: ctrl.isDarkModeSwitch.value,
//             activeColor: AppThemeData.primary300,
//             onChanged: (value) {
//               ctrl.isDarkModeSwitch.value = value;
//               if (value) {
//                 Preferences.setString(Preferences.themKey, 'Dark');
//                 theme.darkTheme = 0;
//               } else if (ctrl.isDarkMode.value == 'Light') {
//                 Preferences.setString(Preferences.themKey, 'Light');
//                 theme.darkTheme = 1;
//               } else {
//                 Preferences.setString(Preferences.themKey, '');
//                 theme.darkTheme = 2;
//               }
//             },
//           )),
//         ),
//       );
//
//   // ── Share ───────────────────────────────────────────────────────────
//   Widget _shareTile(DarkThemeProvider theme) => ListTile(
//     visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
//     contentPadding: EdgeInsets.zero,
//     dense: true,
//     leading: SvgPicture.asset('assets/icons/ic_share.svg'),
//     trailing: const Icon(Icons.keyboard_arrow_right_rounded, size: 24),
//     title: Text('Share app'.tr,
//         style: TextStyle(
//           color: theme.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
//           fontFamily: AppThemeData.semiBold,
//         )),
//     onTap: () {
//       Get.back();
//       Share.share(
//         '${'Check out JippyMart, your ultimate food delivery application!'.tr}'
//             '\n\n${'Google Play:'.tr} ${Constant.googlePlayLink}'
//             '\n\n${'App Store:'.tr} ${Constant.appStoreLink}',
//         subject: 'Look what I made!'.tr,
//       );
//     },
//   );
//
//   // ── Rate ────────────────────────────────────────────────────────────
//   Widget _rateTile(DarkThemeProvider theme) => ListTile(
//     visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
//     contentPadding: EdgeInsets.zero,
//     dense: true,
//     leading: SvgPicture.asset('assets/icons/ic_rate.svg'),
//     trailing: const Icon(Icons.keyboard_arrow_right_rounded, size: 24),
//     title: Text('Rate the app'.tr,
//         style: TextStyle(
//           color: theme.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
//           fontFamily: AppThemeData.semiBold,
//         )),
//     onTap: () {
//       Get.back();
//       InAppReview.instance.requestReview();
//     },
//   );
//
//   // ── Logout ──────────────────────────────────────────────────────────
//   Widget _logoutTile(DarkThemeProvider theme, BuildContext context) => ListTile(
//     visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
//     contentPadding: EdgeInsets.zero,
//     dense: true,
//     leading: SvgPicture.asset('assets/icons/ic_logout.svg',
//         colorFilter: const ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn)),
//     trailing: const Icon(Icons.keyboard_arrow_right_rounded,
//         size: 24, color: AppThemeData.danger300),
//     title: Text('Log out'.tr,
//         style: const TextStyle(
//             color: AppThemeData.danger300, fontFamily: AppThemeData.semiBold)),
//     onTap: () {
//       Get.back();
//       showDialog(
//         context: context,
//         builder: (_) => CustomDialogBox(
//           title: 'Log out'.tr,
//           descriptions:
//           'Are you sure you want to log out? You will need to enter your credentials to log back in.'.tr,
//           positiveString: 'Log out'.tr,
//           negativeString: 'Cancel'.tr,
//           positiveClick: () async {
//             await AudioPlayerService.playSound(false);
//             Constant.userModel!.fcmToken = '';
//             await FireStoreUtils.updateUser(Constant.userModel!);
//             LoginController.logout();
//           },
//           negativeClick: Get.back,
//           img: Image.asset('assets/images/ic_logout.gif', height: 50, width: 50),
//         ),
//       );
//     },
//   );
//
//   // ── Delete account ──────────────────────────────────────────────────
//   Widget _deleteAccountTile(DarkThemeProvider theme, BuildContext context) =>
//       InkWell(
//         onTap: () => showDialog(
//           context: context,
//           builder: (_) => CustomDialogBox(
//             title: 'Delete Account'.tr,
//             descriptions:
//             'Are you sure you want to delete your account? This action is irreversible and will permanently remove all your data.'.tr,
//             positiveString: 'Delete'.tr,
//             negativeString: 'Cancel'.tr,
//             positiveClick: () async {
//               ShowToastDialog.showLoader('Please wait'.tr);
//               final deleted = await FireStoreUtils.deleteUser();
//               ShowToastDialog.closeLoader();
//               if (deleted == true) {
//                 ShowToastDialog.showToast('Account deleted successfully'.tr);
//                 Get.offAll(const LoginScreen());
//               } else {
//                 ShowToastDialog.showToast('Contact Administrator'.tr);
//               }
//             },
//             negativeClick: Get.back,
//             img: Image.asset('assets/icons/delete_dialog.gif', height: 50, width: 50),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SvgPicture.asset('assets/icons/ic_delete.svg',
//                 colorFilter: const ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn)),
//             const SizedBox(width: 10),
//             Text('Delete Account'.tr,
//                 style: const TextStyle(
//                     color: AppThemeData.danger300, fontFamily: AppThemeData.semiBold)),
//           ],
//         ),
//       );
//
//   // ── Helpers ─────────────────────────────────────────────────────────
//   Widget _sectionHeader(String label, DarkThemeProvider theme) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 10),
//     child: Text(label,
//         style: TextStyle(
//           color: theme.getThem() ? AppThemeData.grey400 : AppThemeData.grey500,
//           fontSize: 12,
//           fontFamily: AppThemeData.medium,
//         )),
//   );
//
//   Widget _versionLabel(DarkThemeProvider theme) => Center(
//     child: Text('V : ${Constant.appVersion}',
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           fontFamily: AppThemeData.medium,
//           fontSize: 14,
//           color: theme.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
//         )),
//   );
// }