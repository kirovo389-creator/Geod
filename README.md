# AETHER: Осколки неба — Unity

Android 3D prototype rewritten from Godot to Unity 6 (C#).

## Build locally
Install Unity 6000.0.40f1 with Android Build Support, Android SDK/NDK and OpenJDK. Open this folder in Unity, then build for Android (Landscape).

## GitHub Actions
The Android workflow requires the repository Actions secret UNITY_LICENSE. UNITY_EMAIL and UNITY_PASSWORD may also be required by your Unity license. Without a valid license secret, GitHub Actions cannot build an APK.
