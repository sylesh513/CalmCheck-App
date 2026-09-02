# CalmCheck release shrinking.
#
# Only what R8 cannot see through: platform-channel entry points and the
# reflective corners of the plugins this app uses. Everything else is allowed
# to be stripped — a smaller download is a real feature on the phones this app
# is for.

# ---- Flutter engine -------------------------------------------------------
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# ---- ML Kit barcode scanning (mobile_scanner) -----------------------------
# The models are bundled so scanning works with no signal; the loader finds
# them reflectively.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**

# ---- Local notifications --------------------------------------------------
# Receivers and the Gson-serialised scheduled-notification payload.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}
# R8 full mode strips TypeToken's generic signature without these, and Gson
# then throws "Missing type parameter" deserialising the scheduled-reminder
# payload — a release-only crash, worst on the reboot re-scheduling path.
# These two rules are required by flutter_local_notifications' own docs.
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.gson.**

# ---- Play Billing (purchases_flutter / RevenueCat) -------------------------
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# R8 in full mode strips these annotations otherwise, and the plugins above
# read them.
-keepattributes Signature, InnerClasses, EnclosingMethod, RuntimeVisibleAnnotations

# ---- Play Core deferred components ----------------------------------------
# The Flutter engine references the split-install API for deferred components.
# This app has none, the library is not on the classpath, and R8 only needs to
# be told that is intentional.
-dontwarn com.google.android.play.core.**
