# Keep line numbers for deobfuscation with split debug symbols.
-keepattributes SourceFile,LineNumberTable

# Flutter and Firebase usually work with default rules, but keep annotations.
-keepattributes *Annotation*

# Retain enum helpers used by serializers/deserializers.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
