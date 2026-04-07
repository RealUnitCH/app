# flutter_secure_storage — no consumer rules, uses reflection for
# EncryptedSharedPreferences + Tink
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Tink crypto key types (loaded via reflection by security-crypto)
-keep class com.google.crypto.tink.** { *; }

# AndroidX security-crypto
-keep class androidx.security.crypto.** { *; }

# Preserve native method bindings
-keepclasseswithmembernames class * {
    native <methods>;
}
