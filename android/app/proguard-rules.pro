# Flutter WebView Plugin
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview_android.R$** { *; }  
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.**

# Flutter POS Printer Plugin
-keep class com.sersoluciones.flutter_pos_printer_platform.** { *; }
-keep class com.sersoluciones.flutter_pos_printer_platform.R$** { *; }
-dontwarn com.sersoluciones.flutter_pos_printer_platform.**

# General Flutter plugins
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep all Android resource classes
-keep class **.R$* { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep public class com.extrotarget.extropos.** { *; }
