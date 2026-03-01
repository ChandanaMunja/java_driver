import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jippydriver_driver/app/splash_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/controllers/global_setting_controller.dart';
import 'package:jippydriver_driver/controllers/play_integrity_controller.dart';
import 'package:jippydriver_driver/firebase_options.dart';
import 'package:jippydriver_driver/models/language_model.dart';
import 'package:jippydriver_driver/services/audio_player_service.dart';
import 'package:jippydriver_driver/services/localization_service.dart';
import 'package:jippydriver_driver/services/play_integrity_service.dart';
import 'package:jippydriver_driver/themes/styles.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/utils/notification_service.dart' show NotificationService, firebaseMessageBackgroundHandle;
import 'package:jippydriver_driver/utils/preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'controllers/edit_profile_controller.dart';


// @pragma('vm:entry-point')
// Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   await Preferences.initPref();
//   await AudioPlayerService.initAudio();
//   // Handle background message
//   log("📱 Background FCM received: ${message.messageId}");
//   await AudioPlayerService.playSound(true);
// }

// void main() async {
//   runZonedGuarded(() async {
//     WidgetsFlutterBinding.ensureInitialized(); //<= the key is here

//     FlutterError.onError = (FlutterErrorDetails errorDetails) {};
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     // Initialize Background Service
//     // await initializeBackgroundService();
//     // Initialize Play Integrity Service
//     print('🚀 [Main] Initializing Play Integrity Service...');
//     await PlayIntegrityService.initialize();
//     print('🚀 [Main] ✅ Play Integrity Service initialized');
//     // Initialize Play Integrity Controller
//     print('🚀 [Main] Initializing Play Integrity Controller...');
//     Get.put(PlayIntegrityController(),);
//     print('🚀 [Main] ✅ Play Integrity Controller initialized');
//     await Preferences.initPref();
//     runApp(const MyApp());
//   }, (error, stackTrace) {});
// }
// CRITICAL: Register background message handler at top level BEFORE main()
// This MUST be done here, not inside any function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Import the handler from notification_service
  // This will be called when app is terminated or in background
  await firebaseMessageBackgroundHandle(message);
}

// Add this to your main function
// Add this to your main function
void main() async {
  // runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // CRITICAL: Register background message handler BEFORE Firebase initialization
    // This MUST be at top level, not conditional
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize notifications BEFORE running app
    await NotificationService().initInfo();
    // Initialize other services
    await Preferences.initPref();
    // Restore cached terms & privacy so they're visible before getSettings runs
    final cachedTerms = Preferences.getString(Preferences.cachedTermsAndConditions);
    final cachedPrivacy = Preferences.getString(Preferences.cachedPrivacyPolicy);
    if (cachedTerms.isNotEmpty) Constant.termsAndConditions = cachedTerms;
    if (cachedPrivacy.isNotEmpty) Constant.privacyPolicy = cachedPrivacy;
    await AudioPlayerService.initAudio();
    // Initialize Play Integrity services
    print('🚀 Initializing Play Integrity Service...');
    await PlayIntegrityService.initialize();
    Get.put(PlayIntegrityController());
    Get.put(EditProfileController(), permanent: true);
    runApp(const MyApp());
  // }, (error, stackTrace) {
  //   log('Error in main: $error');
  // });
}

final RxBool isInPipMode = false.obs; // 👈 global reactive variable
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Preferences.getString(Preferences.languageCodeKey)
          .toString()
          .isNotEmpty) {
        LanguageModel languageModel = Constant.getLanguage();
        LocalizationService().changeLocale(languageModel.slug.toString());
      } else {
        LanguageModel languageModel =
        LanguageModel(slug: "en", isRtl: false, title: "English");
        Preferences.setString(
            Preferences.languageCodeKey, jsonEncode(languageModel.toJson()));
      }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      AudioPlayerService.initAudio();
    } else if (state == AppLifecycleState.detached) {
      AudioPlayerService.playSound(false);
    } else {
      isInPipMode.value = false;
    }
    getCurrentAppTheme();
  }
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.inactive) {
  //     AudioPlayerService.initAudio();
  //     // enterPipMode();
  //   }else{
  //     isInPipMode.value = false;
  //   }
  //   getCurrentAppTheme();
  // }
  // Future<void> enterPipMode() async {
  //   try {
  //     await AndroidPIP().enterPipMode(aspectRatio: [7, 9]);
  //     isInPipMode.value = true; // 👈 notify globally
  //   } catch (e) {
  //     debugPrint("Error entering PiP: $e");
  //   }
  // }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
    await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          // Cache theme calculation to avoid recalculation on every rebuild
          final isDarkMode = themeChangeProvider.darkTheme == 0
              ? true
              : themeChangeProvider.darkTheme == 1
                  ? false
                  : false;
          
          return GetMaterialApp(
            title: 'Driver'.tr,
            debugShowCheckedModeBanner: false,
            // Use cached theme value
            theme: Styles.themeData(isDarkMode, context),
            localizationsDelegates: const [CountryLocalizations.delegate],
            locale: LocalizationService.locale,
            fallbackLocale: LocalizationService.locale,
            translations: LocalizationService(),
            builder: EasyLoading.init(),
            // Optimize route transitions for smoother navigation
            transitionDuration: const Duration(milliseconds: 300),
            defaultTransition: Transition.rightToLeft,
            home: GetBuilder<GlobalSettingController>(
              init: GlobalSettingController(),
              builder: (_) => const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}