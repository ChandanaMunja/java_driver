import 'dart:io';

import 'package:jippydriver_driver/constant/constant.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Returns true if the app must show mandatory update (user cannot proceed without updating).
/// Only when show_update is true AND current app version is less than min_app_version from backend.
/// Same version = don't show; lower version = show update screen.
Future<bool> isMandatoryUpdateRequired() async {
  // If backend doesn't want to show update, don't show
  if (!Constant.showUpdate) return false;
  
  final minVer = Constant.minAppVersion.trim();
  if (minVer.isEmpty) return false;
  
  try {
    final info = await PackageInfo.fromPlatform();
    final current = (info.version).trim();
    return _isVersionLessThan(current, minVer);
  } catch (_) {
    return false;
  }
}

/// Compare version strings (e.g. "2.2.5" vs "2.2.4"). Returns true if a < b.
bool _isVersionLessThan(String a, String b) {
  final partsA = a.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
  final partsB = b.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
  final len = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < len; i++) {
    final va = i < partsA.length ? partsA[i] : 0;
    final vb = i < partsB.length ? partsB[i] : 0;
    if (va < vb) return true;
    if (va > vb) return false;
  }
  return false;
}

/// Store URL for the current platform (Google Play or App Store).
String get storeUrlForCurrentPlatform {
  if (Platform.isIOS) {
    return Constant.appStoreLink.isNotEmpty ? Constant.appStoreLink : Constant.googlePlayLink;
  }
  return Constant.googlePlayLink.isNotEmpty ? Constant.googlePlayLink : Constant.appStoreLink;
}
