# Baby Vax R8/ProGuard keep rules.
#
# R8 is enabled for release builds (minifyEnabled + shrinkResources). Flutter,
# Firebase and the notification plugin ship their own consumer rules, so this
# file only holds what is still needed on top.

# flutter_local_notifications serialises scheduled notifications with Gson so
# they survive a reboot. Gson resolves those classes reflectively, so their
# generic signatures and field names must not be stripped or renamed.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep the Gson TypeToken machinery the plugin relies on.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Firebase Crashlytics needs line numbers and source files to symbolicate.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Silence warnings for optional desugar/annotation classes that are not present
# at runtime. These are compile-time only and safe to ignore.
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
