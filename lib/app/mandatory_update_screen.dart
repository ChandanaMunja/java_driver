import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/version_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen mandatory update. Shown when backend sets force_update or min_app_version.
/// User can only proceed by opening the store (no skip).
class MandatoryUpdateScreen extends StatelessWidget {
  const MandatoryUpdateScreen({super.key});

  Future<void> _openStore() async {
    final url = storeUrlForCurrentPlatform;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.driverApp300,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update_alt,
                size: 80,
                color: AppThemeData.grey50,
              ),
              const SizedBox(height: 24),
              Text(
                'Update required'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppThemeData.grey50,
                  fontFamily: AppThemeData.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please update the app to the latest version to continue.'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppThemeData.grey50,
                  fontFamily: AppThemeData.regular,
                ),
                textAlign: TextAlign.center,
              ),
              if (Constant.minAppVersion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Required version: ${Constant.minAppVersion}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppThemeData.grey100,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.grey50,
                    foregroundColor: AppThemeData.driverApp500,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Update'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
