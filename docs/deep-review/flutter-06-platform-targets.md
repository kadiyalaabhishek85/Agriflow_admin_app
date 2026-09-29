# Deep review: Flutter platform targets and assets (leaf 1.1.6)

## Scope

This report covers every file under `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` and `assets/` — 143 files in total (25 Android, 49 iOS, 33 macOS, 18 Windows, 10 Linux, 7 web, 1 asset). Fifteen additional files under `android/.gradle/` were excluded by the coverage checker's skip list, but they are still discussed as stale build cache in the findings. The review is read-only: no build was run and nothing outside `docs/deep-review/flutter-06-platform-targets.md` was written.

The slice was assessed against three questions: which platform files are stock `flutter create` scaffold, which carry deliberate AgriFlow configuration, and what production configuration a distributed admin application still lacks. Ground truth for backend behaviour remains the live FastAPI OpenAPI at `https://agriflow-backend-t8o4.onrender.com`; no endpoint, payload or business rule is inferred anywhere in this document. Where a feature would require server-side support that does not exist yet, it is marked with the required literal sentence.

Headline: every target builds from an unmodified Flutter template identity (`com.example.*`, `agriflow_admin`), the brand logo asset is correctly registered but never used as a launcher or app icon, and the macOS sandbox entitlements omit outbound network access, which would prevent any macOS build from reaching the AgriFlow API at all.

## Files reviewed

FILE: android/.gitignore
FILE: android/agriflow_admin_android.iml
FILE: android/app/build.gradle.kts
FILE: android/app/src/debug/AndroidManifest.xml
FILE: android/app/src/main/AndroidManifest.xml
FILE: android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
FILE: android/app/src/main/kotlin/com/example/agriflow_admin/MainActivity.kt
FILE: android/app/src/main/res/drawable/launch_background.xml
FILE: android/app/src/main/res/drawable-v21/launch_background.xml
FILE: android/app/src/main/res/mipmap-hdpi/ic_launcher.png
FILE: android/app/src/main/res/mipmap-mdpi/ic_launcher.png
FILE: android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
FILE: android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
FILE: android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
FILE: android/app/src/main/res/values/styles.xml
FILE: android/app/src/main/res/values-night/styles.xml
FILE: android/app/src/profile/AndroidManifest.xml
FILE: android/build.gradle.kts
FILE: android/gradle.properties
FILE: android/gradle/wrapper/gradle-wrapper.jar
FILE: android/gradle/wrapper/gradle-wrapper.properties
FILE: android/gradlew
FILE: android/gradlew.bat
FILE: android/local.properties
FILE: android/settings.gradle.kts
FILE: assets/images/sri_siva_sai_seeds_logo.png
FILE: ios/.gitignore
FILE: ios/Flutter/AppFrameworkInfo.plist
FILE: ios/Flutter/Debug.xcconfig
FILE: ios/Flutter/ephemeral/flutter_lldb_helper.py
FILE: ios/Flutter/ephemeral/flutter_lldbinit
FILE: ios/Flutter/ephemeral/flutter_native_integration.env
FILE: ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
FILE: ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Sources/FlutterGeneratedPluginSwiftPackage/FlutterGeneratedPluginSwiftPackage.swift
FILE: ios/Flutter/flutter_export_environment.sh
FILE: ios/Flutter/Generated.xcconfig
FILE: ios/Flutter/Release.xcconfig
FILE: ios/Runner.xcodeproj/project.pbxproj
FILE: ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata
FILE: ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
FILE: ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
FILE: ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
FILE: ios/Runner.xcworkspace/contents.xcworkspacedata
FILE: ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
FILE: ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
FILE: ios/Runner/AppDelegate.swift
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
FILE: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
FILE: ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json
FILE: ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png
FILE: ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png
FILE: ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png
FILE: ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md
FILE: ios/Runner/Base.lproj/LaunchScreen.storyboard
FILE: ios/Runner/Base.lproj/Main.storyboard
FILE: ios/Runner/GeneratedPluginRegistrant.h
FILE: ios/Runner/GeneratedPluginRegistrant.m
FILE: ios/Runner/Info.plist
FILE: ios/Runner/Runner-Bridging-Header.h
FILE: ios/Runner/SceneDelegate.swift
FILE: ios/RunnerTests/RunnerTests.swift
FILE: linux/.gitignore
FILE: linux/CMakeLists.txt
FILE: linux/flutter/CMakeLists.txt
FILE: linux/flutter/generated_plugin_registrant.cc
FILE: linux/flutter/generated_plugin_registrant.h
FILE: linux/flutter/generated_plugins.cmake
FILE: linux/runner/CMakeLists.txt
FILE: linux/runner/main.cc
FILE: linux/runner/my_application.cc
FILE: linux/runner/my_application.h
FILE: macos/.gitignore
FILE: macos/Flutter/ephemeral/flutter_export_environment.sh
FILE: macos/Flutter/ephemeral/flutter_native_integration.env
FILE: macos/Flutter/ephemeral/Flutter-Generated.xcconfig
FILE: macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
FILE: macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Sources/FlutterGeneratedPluginSwiftPackage/FlutterGeneratedPluginSwiftPackage.swift
FILE: macos/Flutter/Flutter-Debug.xcconfig
FILE: macos/Flutter/Flutter-Release.xcconfig
FILE: macos/Flutter/GeneratedPluginRegistrant.swift
FILE: macos/Runner.xcodeproj/project.pbxproj
FILE: macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
FILE: macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
FILE: macos/Runner.xcworkspace/contents.xcworkspacedata
FILE: macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
FILE: macos/Runner/AppDelegate.swift
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
FILE: macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
FILE: macos/Runner/Base.lproj/MainMenu.xib
FILE: macos/Runner/Configs/AppInfo.xcconfig
FILE: macos/Runner/Configs/Debug.xcconfig
FILE: macos/Runner/Configs/Release.xcconfig
FILE: macos/Runner/Configs/Warnings.xcconfig
FILE: macos/Runner/DebugProfile.entitlements
FILE: macos/Runner/Info.plist
FILE: macos/Runner/MainFlutterWindow.swift
FILE: macos/Runner/Release.entitlements
FILE: macos/RunnerTests/RunnerTests.swift
FILE: web/favicon.png
FILE: web/icons/Icon-192.png
FILE: web/icons/Icon-512.png
FILE: web/icons/Icon-maskable-192.png
FILE: web/icons/Icon-maskable-512.png
FILE: web/index.html
FILE: web/manifest.json
FILE: windows/.gitignore
FILE: windows/CMakeLists.txt
FILE: windows/flutter/CMakeLists.txt
FILE: windows/flutter/generated_plugin_registrant.cc
FILE: windows/flutter/generated_plugin_registrant.h
FILE: windows/flutter/generated_plugins.cmake
FILE: windows/runner/CMakeLists.txt
FILE: windows/runner/flutter_window.cpp
FILE: windows/runner/flutter_window.h
FILE: windows/runner/main.cpp
FILE: windows/runner/resource.h
FILE: windows/runner/resources/app_icon.ico
FILE: windows/runner/runner.exe.manifest
FILE: windows/runner/Runner.rc
FILE: windows/runner/utils.cpp
FILE: windows/runner/utils.h
FILE: windows/runner/win32_window.cpp
FILE: windows/runner/win32_window.h

## Findings

**F1 (critical) — macOS sandbox forbids outbound network access, so no macOS build can reach the API.** `macos/Runner/Release.entitlements:5` grants only `com.apple.security.app-sandbox`; the `com.apple.security.network.client` entitlement is absent entirely. The debug file is no better for connectivity: `macos/Runner/DebugProfile.entitlements:5`–`10` grants sandbox, `allow-jit` and `network.server` (server, not client). A sandboxed macOS app without `network.client` is denied outbound sockets, so every macOS build would fail to call `https://agriflow-backend-t8o4.onrender.com`. This is the single most severe platform defect in the slice.

**F2 (critical) — every target still ships the `com.example.*` scaffold identity.** Android uses `namespace = "com.example.agriflow_admin"` (`android/app/build.gradle.kts:8`) and `applicationId = "com.example.agriflow_admin"` (`android/app/build.gradle.kts:19`), directly under the untouched template comment `// TODO: Specify your own unique Application ID` (`android/app/build.gradle.kts:18`); `MainActivity.kt` sits in that namespace (`android/app/src/main/kotlin/com/example/agriflow_admin/MainActivity.kt:1`). Apple targets use a *different* casing of the same placeholder: `PRODUCT_BUNDLE_IDENTIFIER = com.example.agriflowAdmin` (`ios/Runner.xcodeproj/project.pbxproj:385`, `:564`, `:586`; `macos/Runner/Configs/AppInfo.xcconfig:11`) plus `com.example.agriflowAdmin.RunnerTests` (`ios/Runner.xcodeproj/project.pbxproj:401`). Linux hard-codes `set(APPLICATION_ID "com.example.agriflow_admin")` (`linux/CMakeLists.txt:10`), and Windows declares `VALUE "CompanyName", "com.example"` with `VALUE "LegalCopyright", "Copyright (C) 2026 com.example. All rights reserved."` (`windows/runner/Runner.rc:92`, `:96`), mirrored by `PRODUCT_COPYRIGHT = Copyright © 2026 com.example` (`macos/Runner/Configs/AppInfo.xcconfig:14`). So identity is both unbranded and internally inconsistent: snake_case on Android/Linux/Windows, camelCase on iOS/macOS.

**F3 (high) — the visible app name is the raw package name on five of six targets.** Android label is `android:label="agriflow_admin"` (`android/app/src/main/AndroidManifest.xml:5`); macOS `PRODUCT_NAME = agriflow_admin` (`macos/Runner/Configs/AppInfo.xcconfig:8`) which also drives the stock `APP_NAME` menu titles in `macos/Runner/Base.lproj/MainMenu.xib:25`, `:27`, `:29`; the Windows window title is `L"agriflow_admin"` (`windows/runner/main.cpp:30`); Linux sets `gtk_header_bar_set_title(header_bar, "agriflow_admin")` and `gtk_window_set_title(window, "agriflow_admin")` (`linux/runner/my_application.cc:48`, `:52`); and web titles itself `agriflow_admin` (`web/index.html:32`, `web/manifest.json:2`). Only iOS is human-readable — `CFBundleDisplayName` is `Agriflow Admin` (`ios/Runner/Info.plist:10`) while its own `CFBundleName` remains `agriflow_admin` (`ios/Runner/Info.plist:18`). A user installing this on Android sees a developer package name on their home screen.

**F4 (high) — Android release builds are signed with the debug keystore.** `android/app/build.gradle.kts:30` still reads `// TODO: Add your own signing config for the release build.` and `android/app/build.gradle.kts:32` assigns `signingConfig = signingConfigs.getByName("debug")`. This cannot be uploaded to Play Console. The keystore hygiene scaffolding exists (`android/.gitignore:12`–`14` ignore `key.properties`, `**/*.keystore`, `**/*.jks`) but no `key.properties` is present.

**F5 (high) — the web shell and PWA manifest are still template copies.** `web/manifest.json:8` and `web/index.html:21` both carry `A new Flutter project.`, the same placeholder that survives in `pubspec.yaml:2`. Manifest identity is `name`/`short_name` = `agriflow_admin` (`web/manifest.json:2`, `:3`), brand colours are stock Flutter blue `#0175C2` for both `background_color` and `theme_color` (`web/manifest.json:6`, `:7`), `orientation` is locked to `portrait-primary` (`web/manifest.json:9`) which is wrong for a data-dense admin dashboard on a desktop browser, and the manifest defines no `scope` or `id` beyond `start_url: "."` (`web/manifest.json:4`). `web/index.html` ships no `<meta name="theme-color">` (only the Apple status-bar style at `web/index.html:25`), keeps `apple-mobile-web-app-title` as `agriflow_admin` (`web/index.html:26`), and retains the unreplaced `$FLUTTER_BASE_HREF` placeholder (`web/index.html:17`). `web/favicon.png` (917 bytes) and all four `web/icons/*.png` files are the stock Flutter icons.

**F6 (high) — iOS has no entitlements file and therefore no capabilities an admin app needs.** There is no `.entitlements` anywhere under `ios/`; `ios/Runner/Info.plist:4`–`69` defines no `UIBackgroundModes`, no `NSAppTransportSecurity` dictionary, no `CFBundleURLTypes`, no `ITSAppUsesNonExemptEncryption` (App Store export-compliance declaration), and no usage-description keys. Consequently there is no push-notification capability, no background refresh, and no universal-link or custom-scheme deep linking on iOS. Android is equally bare: `android/app/src/main/AndroidManifest.xml:3` grants only `android.permission.INTERNET` (correct and necessary for the HTTPS API), and there is no `android:networkSecurityConfig`, no `POST_NOTIFICATIONS` permission for API 33+, no `FlutterDeepLinkingEnabled` meta-data, and the only intent filter is the stock `MAIN`/`LAUNCHER` pair (`android/app/src/main/AndroidManifest.xml:25`–`28`). The debug and profile manifests re-declare INTERNET for hot-reload (`android/app/src/debug/AndroidManifest.xml:6`, `android/app/src/profile/AndroidManifest.xml:6`), which is expected scaffold.

**F7 (medium) — the brand asset is correctly wired in Dart but never used as any platform icon.** `assets/images/sri_siva_sai_seeds_logo.png` (47,680 bytes) is properly registered: `pubspec.yaml:65` declares `assets:` and `pubspec.yaml:66` declares `- assets/images/`, so the directory — and therefore this PNG — is bundled. It is consumed at `lib/features/auth/presentation/screens/login_screen.dart:132` and `lib/features/auth/presentation/screens/splash_screen.dart:96`. So there is no missing-asset bug. The gap is the inverse: every launcher/app icon in the tree is still the default Flutter mark. Android mipmaps are 442–1,443 bytes (`android/app/src/main/res/mipmap-mdpi/ic_launcher.png` through `mipmap-xxxhdpi`), the iOS `Icon-App-1024x1024@1x.png` is 10,932 bytes, macOS `app_icon_1024.png` and the web icons are likewise stock. The logo never appears on a home screen, a dock, or a browser tab.

**F8 (medium) — launch and splash screens are unbranded stock placeholders.** `android/app/src/main/res/drawable/launch_background.xml:4` is a bare white layer-list with the sample bitmap commented out at `:6`–`:11`; the v21 variant uses `?android:colorBackground` (`android/app/src/main/res/drawable-v21/launch_background.xml:4`). Themes are the untouched `Theme.Light.NoTitleBar` / `Theme.Black.NoTitleBar` pair (`android/app/src/main/res/values/styles.xml:4`, `android/app/src/main/res/values-night/styles.xml:4`). iOS `ios/Runner/Base.lproj/LaunchScreen.storyboard:25` is a white background holding a `LaunchImage` image view, and all three `LaunchImage` PNGs are byte-identical 68-byte transparent placeholders (`ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`, `@2x`, `@3x` share one MD5), so the @2x/@3x assets are degenerate duplicates rather than real resolutions. The asset catalog even ships a documentation file, `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`, which is scaffold that should not ship inside a release bundle.

**F9 (medium) — generated, machine-specific files are present in the workspace even though the templates explicitly ignore them.** `android/local.properties:1`–`2` hard-code `sdk.dir=C:\Android\Sdk` and `flutter.sdk=C:\Users\DELL\Downloads\flutter`, despite `android/.gitignore:6` ignoring `/local.properties`. `ios/Flutter/Generated.xcconfig:2` and `ios/Flutter/flutter_export_environment.sh:2` both embed `FLUTTER_ROOT=C:\Users\DELL\Downloads\flutter`, though `ios/.gitignore:21` ignores `Flutter/Generated.xcconfig` and `ios/.gitignore:26` ignores `Flutter/flutter_export_environment.sh`; `ios/.gitignore:22` ignores `Flutter/ephemeral/` yet the whole `ios/Flutter/ephemeral/` tree (including `flutter_lldbinit`, `flutter_lldb_helper.py`, `flutter_native_integration.env` and the generated Swift package) is present, as is `macos/Flutter/ephemeral/Flutter-Generated.xcconfig:2` (ignored by `macos/.gitignore:1`). `ios/.gitignore:28` ignores `Runner/GeneratedPluginRegistrant.*` while `ios/Runner/GeneratedPluginRegistrant.m` and `.h` sit in the tree. `android/.gitignore:2` ignores `/.gradle`, yet fifteen Gradle 9.1.0 cache files exist under `android/.gradle/`. `android/agriflow_admin_android.iml` is an Android Studio module file with no build role. None of this breaks a build, but all of it is stale, machine-locked and should not travel with the repository.

**F10 (medium) — desktop targets compile a JVM bridge plugin they cannot use, and register nothing else.** `windows/flutter/generated_plugins.cmake:12` and `linux/flutter/generated_plugins.cmake:12` both append `jni` to `FLUTTER_FFI_PLUGIN_LIST`, so every Windows and Linux build compiles the Dart↔JVM interop library — a transitive dependency (`pubspec.lock:163`) with no Java runtime to talk to on those platforms. Meanwhile the actual native registrants are empty: `windows/flutter/generated_plugin_registrant.cc:9` and `linux/flutter/generated_plugin_registrant.cc:9` define a `RegisterPlugins` that registers nothing. On the platforms that do register plugins the surface is also thin: Android adds `jni`, `jni_flutter` and `shared_preferences` (`android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:19`–`31`), iOS registers only `shared_preferences_foundation` (`ios/Runner/GeneratedPluginRegistrant.m:18`), and macOS likewise (`macos/Flutter/GeneratedPluginRegistrant.swift:10`). For an admin application that reviews KYC and grain records, there is currently no image-picker, camera, file-download, notification or connectivity plugin wired on any platform.

**F11 (low) — test targets are empty stubs and macOS's test target cannot be signed as configured.** `ios/RunnerTests/RunnerTests.swift:8` and `macos/RunnerTests/RunnerTests.swift:8` contain only a commented `testExample()` placeholder. Worse, the macOS project marks one target `ProvisioningStyle = Manual` (`macos/Runner.xcodeproj/project.pbxproj:257`) with an empty `PROVISIONING_PROFILE_SPECIFIER` (`macos/Runner.xcodeproj/project.pbxproj:496`), while the other uses Automatic (`macos/Runner.xcodeproj/project.pbxproj:248`); combined with no `DEVELOPMENT_TEAM` anywhere in either Xcode project, iOS and macOS cannot sign for device or distribution until that is filled in.

**F12 (low) — deployment floors and pinned toolchain are stock but worth recording.** iOS is pinned to `IPHONEOS_DEPLOYMENT_TARGET = 13.0` (`ios/Runner.xcodeproj/project.pbxproj:363`, `:489`) and macOS to `MACOSX_DEPLOYMENT_TARGET = 10.15` (`macos/Runner.xcodeproj/project.pbxproj:474`). Android pins AGP `9.0.1` and Kotlin `2.3.20` (`android/settings.gradle.kts:22`, `:23`) with Gradle wrapper `gradle-9.1.0-all` (`android/gradle/wrapper/gradle-wrapper.properties:5`), and `android/gradle.properties:1` deliberately raises the heap to `-Xmx8G -XX:MaxMetaspaceSize=4G` — a real project tuning change, not template default. `android/gradle.properties:4` and `:6` set the template's `android.newDsl=false` and `android.builtInKotlin=false` flags.

## Recommendations

1. **P0 — add `com.apple.security.network.client` to both macOS entitlements.** Without it `macos/Runner/Release.entitlements:5`–`7` and `macos/Runner/DebugProfile.entitlements:5`–`11` leave every macOS build unable to open an outbound socket to the FastAPI backend. This is a one-line fix per file and blocks all other macOS work.
2. **P0 — replace the scaffold application identity on every target before any store submission.** Change `android/app/build.gradle.kts:8` and `:19` to a real reverse-DNS id (and move `MainActivity.kt` out of `com/example/agriflow_admin/`), replace `com.example.agriflowAdmin` at `ios/Runner.xcodeproj/project.pbxproj:385` and `macos/Runner/Configs/AppInfo.xcconfig:11`, replace `linux/CMakeLists.txt:10`, and fix `windows/runner/Runner.rc:92` and `:96`. Pick one casing convention and use it on all six targets so attribution, deep-link hosts and store listings agree.
3. **P0 — configure a real release signing key for Android.** Replace the debug-signing fallback at `android/app/build.gradle.kts:32` with a `key.properties`-driven release config; the ignore rules for it already exist at `android/.gitignore:12`.
4. **P1 — give the app one consistent display name.** Set `android:label` (`android/app/src/main/AndroidManifest.xml:5`) to the same human name already used by iOS (`ios/Runner/Info.plist:10`), then propagate it to `macos/Runner/Configs/AppInfo.xcconfig:8`, `windows/runner/main.cpp:30`, `linux/runner/my_application.cc:48` and `:52`, `web/index.html:32`, and `web/manifest.json:2`–`3`.
5. **P1 — replace the template web shell and PWA metadata.** Rewrite the descriptions at `web/manifest.json:8` and `web/index.html:21`, rebrand `web/manifest.json:6`–`7` away from Flutter blue, drop the `portrait-primary` lock at `web/manifest.json:9` for a dashboard used on wide screens, add `scope` alongside `start_url` (`web/manifest.json:4`), add `<meta name="theme-color">` to `web/index.html`, and regenerate `web/favicon.png` plus the four `web/icons/*.png` from the brand mark.
6. **P1 — generate branded launcher icons from `assets/images/sri_siva_sai_seeds_logo.png`.** The asset is already registered (`pubspec.yaml:65`–`66`) and referenced (`lib/features/auth/presentation/screens/login_screen.dart:132`), so only icon generation is missing; it must cover `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `macos/Runner/Assets.xcassets/AppIcon.appiconset/`, `web/icons/` and `windows/runner/resources/app_icon.ico`.
7. **P1 — brand the launch experience.** Populate the commented slot at `android/app/src/main/res/drawable/launch_background.xml:6`–`11`, colour both `values/styles.xml:4` and `values-night/styles.xml:4`, replace the white canvas at `ios/Runner/Base.lproj/LaunchScreen.storyboard:25`, and replace the three identical placeholder PNGs in `ios/Runner/Assets.xcassets/LaunchImage.imageset/`.
8. **P2 — decide and declare the notification, deep-link and network-security posture.** If the admin app will receive reminders for farm visits or KYC queues, add `POST_NOTIFICATIONS` to `android/app/src/main/AndroidManifest.xml`, add `UIBackgroundModes` and the push entitlement to `ios/Runner/Info.plist` plus a new `ios/Runner/*.entitlements`, and declare URL schemes / `FlutterDeepLinkingEnabled` on Android and `CFBundleURLTypes` on iOS. If a network security config is wanted for certificate pinning or to lock cleartext off, add it under `android/app/src/main/res/xml/` and reference it from `android/app/src/main/AndroidManifest.xml:4`. Deep-link host verification files (`assetlinks.json`, `apple-app-site-association`) must be served from the application domain.

Backend API required - to be supplied by Syed.

9. **P2 — add the App Store compliance and signing keys.** Add `ITSAppUsesNonExemptEncryption` to `ios/Runner/Info.plist`, set `DEVELOPMENT_TEAM` in `ios/Runner.xcodeproj/project.pbxproj` and `macos/Runner.xcodeproj/project.pbxproj`, and flip the Manual provisioning at `macos/Runner.xcodeproj/project.pbxproj:257` (with its empty profile specifier at `:496`) back to Automatic so `macos/RunnerTests/RunnerTests.swift` can run.
10. **P2 — purge machine-generated and IDE files from the tree.** Remove `android/local.properties`, `android/agriflow_admin_android.iml`, the `android/.gradle/` cache directory, `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`, the `ios/Flutter/ephemeral/` and `macos/Flutter/ephemeral/` trees, and `macos/Flutter/ephemeral/Flutter-Generated.xcconfig` — every one of them is already declared ignorable by `android/.gitignore:2` and `:6`, `ios/.gitignore:21`, `:22`, `:26`, `ios/.gitignore:28` and `macos/.gitignore:1`. Also drop the shipped doc file `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`.
11. **P2 — trim the desktop plugin set.** Remove the `jni` FFI entry from `windows/flutter/generated_plugins.cmake:12` and `linux/flutter/generated_plugins.cmake:12` (or eliminate the transitive dependency behind it, `pubspec.lock:163`), then evaluate which plugins the admin role genuinely needs on desktop — none are registered today at `windows/flutter/generated_plugin_registrant.cc:9` or `linux/flutter/generated_plugin_registrant.cc:9`.
12. **P3 — replace the placeholder tests.** Both `ios/RunnerTests/RunnerTests.swift:8` and `macos/RunnerTests/RunnerTests.swift:8` should hold at least a smoke assertion so the test targets are wired into CI rather than silently passing.

## Per-platform inventory

**Android — 25 files.** Entry point is `android/app/src/main/kotlin/com/example/agriflow_admin/MainActivity.kt:5`, a five-line `FlutterActivity` subclass. Build config is Kotlin DSL: `android/build.gradle.kts` (root, redirects build output), `android/settings.gradle.kts` (AGP 9.0.1, Kotlin 2.3.20, `include(":app")` at `android/settings.gradle.kts:26`), `android/app/build.gradle.kts` (namespace, applicationId, SDK levels, release build type), `android/gradle.properties` (JVM heap tuning, `newDsl`/`builtInKotlin` flags), and the Gradle 9.1.0 wrapper (`android/gradle/wrapper/gradle-wrapper.properties:5`, plus `gradlew`/`gradlew.bat`). Manifests exist for all three variants: main (`android/app/src/main/AndroidManifest.xml`), debug (`android/app/src/debug/AndroidManifest.xml`), profile (`android/app/src/profile/AndroidManifest.xml`). Resources: one `drawable/launch_background.xml`, one `drawable-v21/` variant, five density `mipmap-*/ic_launcher.png` files, and light/night `styles.xml` pairs. Plus the generated `GeneratedPluginRegistrant.java`, `android/local.properties`, `android/agriflow_admin_android.iml`, `android/.gitignore`, and 15 ignored `android/.gradle/` cache files. There is no `res/xml/` network security config and no notification icon or adaptive-icon resource.

**iOS — 49 files.** Entry point `ios/Runner/AppDelegate.swift:5` (`@main` `FlutterAppDelegate`) with `ios/Runner/SceneDelegate.swift:4` (`FlutterSceneDelegate`) and `ios/Runner/Runner-Bridging-Header.h:1`. Build config: `ios/Runner.xcodeproj/project.pbxproj`, workspace and shared scheme (`ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme:18` — `Runner.app`), `ios/Flutter/AppFrameworkInfo.plist`, `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` (each a single `#include "Generated.xcconfig"`), plus generated `ios/Flutter/Generated.xcconfig` and `ios/Flutter/flutter_export_environment.sh`. `ios/Runner/Info.plist` carries display name, orientations and the scene manifest. Asset catalogs: 16 `AppIcon` PNGs plus `Contents.json`, three `LaunchImage` PNGs, `Contents.json` and a `README.md`. Storyboards: `LaunchScreen.storyboard` and `Main.storyboard` under `ios/Runner/Base.lproj/`. Generated registrant `.h`/`.m`, `ios/RunnerTests/RunnerTests.swift`, `.gitignore`, the Xcode workspace/plist boilerplate and the `ios/Flutter/ephemeral/` debug tree (LLDB helper, Swift package) complete the set. No entitlements file, no `GoogleService-Info.plist`, no `Podfile` (this project uses Swift Package Manager for plugins).

**macOS — 33 files.** Entry point `macos/Runner/AppDelegate.swift` with `macos/Runner/MainFlutterWindow.swift:7` registering plugins. Build config: `macos/Runner.xcodeproj/project.pbxproj`, shared scheme building `agriflow_admin.app` (`macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme:18`), and four `macos/Runner/Configs/*.xcconfig` files — `AppInfo.xcconfig` (name, bundle id, copyright), `Debug.xcconfig`, `Release.xcconfig`, `Warnings.xcconfig`. `macos/Runner/Info.plist` is stock (`NSMainNibFile` `MainMenu`, `NSPrincipalClass` `NSApplication`). Entitlements exist for Debug/Profile and Release, both sandboxed. Asset catalog: 7 `app_icon_*.png` plus `Contents.json`; `macos/Runner/Base.lproj/MainMenu.xib` holds the full stock application menu with `APP_NAME` title tokens. Flutter side: `macos/Flutter/Flutter-Debug.xcconfig`, `Flutter-Release.xcconfig`, generated `GeneratedPluginRegistrant.swift`, plus an `ephemeral/` tree. `macos/RunnerTests/RunnerTests.swift` and `.gitignore` close it out.

**Windows — 18 files.** Entry point `windows/runner/main.cpp:12` (`wWinMain`), creating a `FlutterWindow` of 1280×720 (`windows/runner/main.cpp:29`) titled `agriflow_admin` (`windows/runner/main.cpp:30`). Build config `windows/CMakeLists.txt` (`project(agriflow_admin)`), `windows/flutter/CMakeLists.txt` (includes `ephemeral/generated_config.cmake` at `windows/flutter/CMakeLists.txt:9`), `windows/runner/CMakeLists.txt` listing the runner sources. Runner support code: `flutter_window.cpp`/`.h`, `win32_window.cpp`/`.h` (window class `FLUTTER_RUNNER_WIN32_WINDOW`, `windows/runner/win32_window.cpp:19`), `utils.cpp`/`.h`. Version and branding live in `windows/runner/Runner.rc` (CompanyName/FileDescription/ProductName, `:92`–`:98`) with `windows/runner/resource.h` (`IDI_APP_ICON`) and `windows/runner/resources/app_icon.ico`. `windows/runner/runner.exe.manifest` declares PerMonitorV2 DPI awareness and Windows 10/11 compatibility. Generated: `windows/flutter/generated_plugin_registrant.cc`/`.h` and `generated_plugins.cmake`. Plus `windows/.gitignore`.

**Linux — 10 files.** Entry point `linux/runner/main.cc:4` (`g_application_run`). Build config `linux/CMakeLists.txt` (`project(agriflow_admin)` at `:3`, `APPLICATION_ID` passed as a compile definition at `linux/CMakeLists.txt:20`), `linux/flutter/CMakeLists.txt`, `linux/runner/CMakeLists.txt`. GTK application `linux/runner/my_application.cc` (header-bar title at `:48`, GApplication id at `:143`) with `linux/runner/my_application.h`. Generated `linux/flutter/generated_plugin_registrant.cc`/`.h` and `generated_plugins.cmake`. Plus `linux/.gitignore`. There is no `.desktop` file, no appdata/metainfo, and no icon installed alongside the binary.

**Web — 7 files.** Shell `web/index.html` (base href placeholder, meta tags, `flutter_bootstrap.js` loader at `web/index.html:44`), PWA `web/manifest.json`, `web/favicon.png`, and four icons: `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`. There is no `web/icons/Icon-512-outline` variant, no service worker file (Flutter emits it at build time), and no custom `flutter_bootstrap.js`.

**Assets — 1 file.** `assets/images/sri_siva_sai_seeds_logo.png` (47,680 bytes), registered through the `assets/images/` directory entry at `pubspec.yaml:66` and referenced from the login and splash screens.

## Hand-edited versus generated

**Android.** Generated scaffold: `android/build.gradle.kts`, `android/settings.gradle.kts`, `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/*`, `android/.gitignore`, `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`, the five `mipmap-*/ic_launcher.png`, `drawable*/launch_background.xml`, `values*/styles.xml`, and the debug/profile manifests. Deliberate project configuration: `android/app/build.gradle.kts:8` `namespace` and `:19` `applicationId` (both still the `com.example.agriflow_admin` default — deliberately *not* yet set to a shipping id), `android/app/src/main/AndroidManifest.xml:2`–`3` (the comment `Required for API communication with AgriFlow backend` and the added `INTERNET` permission — a genuine hand edit), `android/app/src/main/AndroidManifest.xml:5` `android:label="agriflow_admin"`, `android/gradle.properties:1` (raised to `-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m`, well above template default), `android/gradle.properties:4` and `:6` (the template's `newDsl`/`builtInKotlin` opt-outs), and `android/settings.gradle.kts:22`–`:23` (AGP 9.0.1 / Kotlin 2.3.20 pins). Machine-generated and out of place: `android/local.properties:1`–`2`, `android/agriflow_admin_android.iml`, and the ignored `android/.gradle/` cache.

**iOS.** Generated scaffold: everything under `ios/Flutter/` except deliberate edits (xcconfigs, `AppFrameworkInfo.plist`, `ephemeral/`, `Generated.xcconfig`, `flutter_export_environment.sh`), `ios/Runner.xcodeproj/project.pbxproj` scaffolding and workspaces, `ios/Runner/Base.lproj/*.storyboard`, the `AppIcon` and `LaunchImage` asset catalogs, `AppDelegate.swift`, `SceneDelegate.swift`, `GeneratedPluginRegistrant.*`, `Runner-Bridging-Header.h`, `RunnerTests.swift`, `.gitignore`. Deliberate project configuration: `ios/Runner/Info.plist:9`–`10` sets `CFBundleDisplayName` to `Agriflow Admin` (the single most intentional branding edit in the whole slice), while `ios/Runner/Info.plist:17`–`18` keeps `CFBundleName` as `agriflow_admin`. Everything else in that plist (`CADisableMinimumFrameDurationOnPhone:5`, scene manifest `:29`–`49`, orientations `:56`–`68`, launch/main storyboard keys `:52`–`55`) is stock template. Identity is still scaffold: `PRODUCT_BUNDLE_IDENTIFIER = com.example.agriflowAdmin` at `ios/Runner.xcodeproj/project.pbxproj:385`, `.RunnerTests` at `:401`, no `DEVELOPMENT_TEAM`, `IPHONEOS_DEPLOYMENT_TARGET = 13.0` at `:363`.

**macOS.** Generated scaffold: `macos/Runner.xcodeproj/project.pbxproj`, scheme/workspace plists, `macos/Runner/Info.plist`, `MainMenu.xib`, `AppIcon` PNGs and `Contents.json`, `MainFlutterWindow.swift`, `AppDelegate.swift`, `GeneratedPluginRegistrant.swift`, `Configs/Debug.xcconfig`, `Configs/Release.xcconfig`, `Configs/Warnings.xcconfig`, `RunnerTests.swift`, `.gitignore`, and the whole `macos/Flutter/ephemeral/` tree. Deliberate project configuration: `macos/Runner/Configs/AppInfo.xcconfig:8` `PRODUCT_NAME = agriflow_admin`, `:11` `PRODUCT_BUNDLE_IDENTIFIER = com.example.agriflowAdmin`, `:14` `PRODUCT_COPYRIGHT = Copyright © 2026 com.example` — the bundle id and copyright line are template-derived and must be treated as unconfigured. Entitlements are effectively stock: `macos/Runner/DebugProfile.entitlements:5`–`10` (app-sandbox, allow-jit, network.server) and `macos/Runner/Release.entitlements:5`–`6` (app-sandbox only) — the absence of `com.apple.security.network.client` in both is the notable omission. `macos/Runner.xcodeproj/project.pbxproj:248`/`:257` split Automatic/Manual provisioning is untouched template behaviour.

**Windows.** Entirely generated except for branding strings: `windows/CMakeLists.txt:3` `project(agriflow_admin)`, `windows/CMakeLists.txt:7` `BINARY_NAME "agriflow_admin"`, `windows/runner/Runner.rc:92`–`98` (`CompanyName` `com.example`, `FileDescription`/`ProductName` `agriflow_admin`, `LegalCopyright` `Copyright (C) 2026 com.example`), and the window title at `windows/runner/main.cpp:30`. `windows/runner/resources/app_icon.ico` and `windows/runner/resource.h:5` (`IDI_APP_ICON 101`) are stock Flutter. `windows/runner/runner.exe.manifest` (PerMonitorV2 DPI, OS compatibility) is stock. The empty `windows/flutter/generated_plugin_registrant.cc:9` and the `jni` entry at `windows/flutter/generated_plugins.cmake:12` are generated output, not authored configuration.

**Linux.** Fully generated apart from identity: `linux/CMakeLists.txt:3` project name, `:7` `BINARY_NAME`, `:10` `APPLICATION_ID "com.example.agriflow_admin"`, and the two GTK title literals at `linux/runner/my_application.cc:48` and `:52`. `linux/flutter/generated_plugin_registrant.cc:9` and `generated_plugins.cmake:12` are generated. `linux/.gitignore` is a single stock line.

**Web.** Generated shell with no deliberate rebranding: `web/index.html:17` base-href placeholder, `:21` stock description, `:26` `apple-mobile-web-app-title` `agriflow_admin`, `:30` stock favicon link, `:32` `<title>agriflow_admin</title>`; `web/manifest.json:2`–`3` identity, `:6`–`7` Flutter-blue colours, `:8` stock description, `:9` portrait lock. All five PNGs are stock Flutter icons. No deliberate production configuration exists in `web/` yet.

**Assets.** `assets/images/sri_siva_sai_seeds_logo.png` is the only deliberately supplied asset in the repository; registration via `pubspec.yaml:65`–`66` and consumption at `lib/features/auth/presentation/screens/login_screen.dart:132` and `lib/features/auth/presentation/screens/splash_screen.dart:96` are both correct and complete — but the same logo has not been propagated into any platform icon slot.
