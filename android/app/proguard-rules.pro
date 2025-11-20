#################################
# FLUTTER CORE
#################################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }

#################################
# REFLECTION / ANNOTATIONS
#################################
-keepattributes *Annotation*,InnerClasses,EnclosingMethod
-keep @interface proguard.annotation.Keep
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

#################################
# FIREBASE (Auth, Firestore, Messaging, Crashlytics)
#################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keepattributes SourceFile,LineNumberTable
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

#################################
# STRIPE
#################################
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
-keep class org.jetbrains.annotations.** { *; }
-keep class org.jetbrains.annotations.VisibleForTesting { *; }
-dontwarn org.jetbrains.annotations.**

#################################
# RAZORPAY
#################################
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }
-dontwarn com.razorpay.**

#################################
# RETROFIT / OKHTTP
#################################
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keep class com.squareup.okhttp3.** { *; }
-dontwarn okhttp3.**

#################################
# GSON
#################################
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keepattributes Signature
-keepattributes *Annotation*
-keepnames class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

#################################
# GLIDE
#################################
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep public class * extends com.bumptech.glide.AppGlideModule

#################################
# ROOM DATABASE
#################################
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

#################################
# ANDROIDX & MULTIDEX
#################################
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class android.support.** { *; }
-dontwarn android.support.**
-keep class androidx.multidex.** { *; }

#################################
# KOTLIN
#################################
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
-keepattributes *Annotation*
-keepclassmembers class * {
    @kotlin.Metadata <methods>;
}

#################################
# WORKMANAGER
#################################
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

#################################
# LOGGING (Timber, etc.)
#################################
-keep class timber.log.** { *; }
-dontwarn timber.log.**

#################################
# GOOGLE PLAY CORE
#################################
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.assetpacks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.ktx.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Google Pay classes
-keep class com.google.android.apps.nbu.paisa.** { *; }

# General rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Play Core model classes
-keep class com.google.android.play.core.assetpacks.model.** { *; }

# Keep Task related classes
-keep class com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class com.google.android.play.core.tasks.OnFailureListener { *; }
-keep class com.google.android.play.core.tasks.Task { *; }
-keep class com.google.android.play.core.tasks.RuntimeExecutionException { *; }

# Keep specific Play Core classes that were reported as missing
-keep class com.google.android.play.core.assetpacks.AssetLocation { *; }
-keep class com.google.android.play.core.assetpacks.AssetPackLocation { *; }
-keep class com.google.android.play.core.assetpacks.AssetPackManager { *; }
-keep class com.google.android.play.core.assetpacks.AssetPackState { *; }
-keep class com.google.android.play.core.assetpacks.AssetPackStateUpdateListener { *; }
-keep class com.google.android.play.core.assetpacks.AssetPackStates { *; }
-keep class com.google.android.play.core.assetpacks.model.AssetPackErrorCode { *; }
-keep class com.google.android.play.core.assetpacks.model.AssetPackStatus { *; }
-keep class com.google.android.play.core.assetpacks.model.AssetPackStorageMethod { *; }

# Keep JetBrains annotations
-keep class org.jetbrains.annotations.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.assetpacks.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }

# Keep Jetbrains annotations
-keep class org.jetbrains.annotations.** { *; }

# Keep Stripe classes
-keep class com.stripe.android.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Keep Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep Google Play Services classes
-keep class com.google.android.gms.** { *; }

# === Flutter Play Store Deferred Component Support ===
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }