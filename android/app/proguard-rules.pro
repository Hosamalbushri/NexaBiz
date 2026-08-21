# NexaBiz Production ProGuard / R8 Rules

# Flutter Engine & Plugin Obfuscation Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Drift / SQLite3 / SQLiteMC / FFI Native Classes
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-keep class org.sqlite.** { *; }
-keep class com.simolus3.sqlite3.** { *; }
-keep class io.simolus.sqlite3.** { *; }

# Hive Persistence Adapters & Generated Type Adapters
-keep class com.hive.** { *; }
-keep class hive.** { *; }
-keep @interface com.hive.** { *; }

# Sentry Error Tracking SDK
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Syncfusion Charts & DataGrid Keep Rules
-keep class com.syncfusion.** { *; }

# Stack Trace & Source Line Preservation for Crash Reporting
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,Signature,*Annotation*
