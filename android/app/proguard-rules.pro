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
-keep class * extends android.app.NotificationChannel { *; }
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# ---- Play Billing (in_app_purchase) ---------------------------------------
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# ---- Text to speech -------------------------------------------------------
-keep class android.speech.tts.** { *; }

# R8 in full mode strips these annotations otherwise, and the plugins above
# read them.
-keepattributes Signature, InnerClasses, EnclosingMethod, RuntimeVisibleAnnotations

# ---- Play Core deferred components ----------------------------------------
# The Flutter engine references the split-install API for deferred components.
# This app has none, the library is not on the classpath, and R8 only needs to
# be told that is intentional.
-dontwarn com.google.android.play.core.**
