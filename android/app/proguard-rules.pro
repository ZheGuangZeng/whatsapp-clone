# Flutter specific ProGuard rules for WhatsApp Clone

# Keep all Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep all classes that use reflection
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel.Result *;
    @io.flutter.plugin.common.PluginRegistry.Registrar *;
}

# Keep Supabase classes
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep LiveKit classes  
-keep class io.livekit.** { *; }
-dontwarn io.livekit.**

# Keep WebRTC classes used by LiveKit
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Keep file picker classes
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# Keep image picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# Keep secure storage classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Keep shared preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# Keep path provider classes
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# Keep URL launcher classes
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# General Android rules
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}