# ML Kit Keep Rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_korean.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_chinese.** { *; }

# Keep the TextRecognition classes
-keep class com.google.mlkit.vision.text.** { *; }

# General Google Play Services keep rules
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
