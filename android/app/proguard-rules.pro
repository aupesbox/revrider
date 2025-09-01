# --- Keep Spotify SDK & Jackson deserializers ---
-keep class com.spotify.** { *; }
-dontwarn com.spotify.**

-keep class com.fasterxml.jackson.databind.** { *; }
-dontwarn com.fasterxml.jackson.databind.**

-keep class com.fasterxml.jackson.annotation.** { *; }
-dontwarn com.fasterxml.jackson.annotation.**

# Keep inner class deserializers and serializers
-keep class **$Deserializer { *; }
-keep class **$Serializer { *; }

# Optional but safe
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
