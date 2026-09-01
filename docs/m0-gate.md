# M0 gate — opencv_dart on-device go/no-go

Status: **host side PASSED; device side pending** (needs a physical arm64 Android phone).

## Host results (2026-08-31)

| Check | Result |
|---|---|
| `flutter test` in `packages/omr_detect` | **49/49 pass**, incl. the 6-test cv smoke (`test/cv_smoke_test.dart`) |
| Trimmed module set | `core + imgproc + imgcodecs + calib3d` — every pipeline call the smoke pins resolves |
| Quad-detect frame time, 640×480, host | **~490 µs/frame (≈2000 fps)** vs the ≤32 ms low-end device budget (≈65× headroom on host) |
| Full workspace suites | omr_spec 65 · omr_core 110 · omr_detect 49 · omr_data 37 · omr_reports 8 · app 5 |

The smoke pins one symbol family per pipeline stage: `cvtColor`+`mean`, `matchTemplate`+`minMaxLoc`
(quadrant-restricted), `getPerspectiveTransform`+`warpPerspective`, `Laplacian`+`meanStdDev`
(variance-of-Laplacian), and the capture-loop chain `gaussianBlur → canny → morphologyEx →
findContours → contourArea → arcLength → approxPolyDP`. Excluded modules throw at *runtime*, not
build time — which is exactly why each call must be exercised, not just compiled.

## Device results

- [ ] `integration_test` smoke on a real arm64 Android device (same six call families + timed
      640×480 quad-detect frame, judged against ≤32 ms). Driver:
      `app/integration_test/smoke_test.dart` — it runs the SAME `runCvSmokeProbe` the host suite
      runs, so the criteria cannot drift. Needs a physical phone:
      `flutter test integration_test/smoke_test.dart -d <device-id>`.
- [x] **Debug APK builds with the NDK-compiled OpenCV bundled** — `flutter build apk --debug
      --target-platform android-arm64` → `lib/arm64-v8a/libdartcv.so` (11.5 MB) alongside
      libflutter/libsqlite3 (2026-08-31).
- [x] **`zipalign -c -P 16` passes** on that APK; `libdartcv.so` and `libflutter.so` both
      verified OK at 16 KB page alignment (NDK r28c default, confirmed not assumed).
- [ ] Native-fallback decision recorded: any missing symbol, >32 ms timed frame on the low-end
      device ⇒ keep Flutter UI/spec/reports, port the live quad loop to a Kotlin platform channel
      behind `EdgeAnalyzer` (opencv_dart continues to serve the still pipeline).

## Toolchain notes (how the native build was made to work here)

This machine has **Command Line Tools only — no full Xcode**. The dartcv4 2.3.0 build hook
(native_toolchain_cmake 0.3.2) needs four non-obvious things as a result. Recorded so a clean
machine reproduces in one pass instead of seven:

1. **Hook user-defines live in the WORKSPACE ROOT `pubspec.yaml`.** In a pub workspace, member
   packages' `hooks:` blocks are ignored — `omr_detect`'s own pubspec carries the *dependency*, the
   root carries the *config*.

2. **`android_home` is only honored inside the `android:` sub-map** of the dartcv4 user-defines.
   The parser ignores it at the top level. It gates the Android-SDK cmake/ninja lookup for *every*
   target OS (the resolver probes `<android_home>/cmake/*/bin/`), which is how the macOS target
   gets pinned to the SDK's CMake 3.22.1:

   ```yaml
   hooks:
     user_defines:
       dartcv4:
         include_modules: [imgcodecs, imgproc, calib3d]
         android:
           android_home: /opt/homebrew/share/android-commandlinetools
         macos:
           generator: Ninja        # default Xcode generator needs full Xcode
           cmake_version: 3.22.1   # see (3)
           prefer_android_cmake: true
           prefer_android_ninja: true
   ```

3. **CMake 4.x cannot drive `ios.toolchain.cmake`.** Line 668 uses the legacy 3-arg
   `get_filename_component(<dir> <path> PATH)` form, removed in CMake 4 — Homebrew's 4.2.3 fails
   there even with a valid sysroot. The Android SDK's CMake 3.22.1 (`prefer_android_cmake: true`)
   still accepts it. (The same line-668 error is ALSO what an empty sysroot produces — the two
   causes were conflated for several iterations.)

4. **Without `xcodebuild` the sysroot resolves empty**, because the toolchain shell-outs to
   `xcodebuild -version -sdk macosx Path`. It honors `ENV{_CMAKE_OSX_SYSROOT_INT}` and
   `ENV{_SDK_VERSION}` — but ONLY from a clean build dir: a failed configure caches the empty
   sysroot as `CACHE INTERNAL`, and the cache branch then *overwrites* the env var on every retry.
   Working sequence (CLT SDK is 27.0 on this machine):

   ```sh
   rm -rf .dart_tool/hooks_runner/shared/dartcv4/build/<hash>
   env _CMAKE_OSX_SYSROOT_INT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
       _SDK_VERSION=27.0 \
   <SDK cmake 3.22.1> <same -S/-B/-D flags the hook prints>   # seed the cache
   flutter test packages/omr_detect   # re-configure is a no-op; proceeds to build
   ```

   `xcrun -find clang/libtool` work fine under CLT, so compilers resolve once the sysroot does.
   When full Xcode is ever installed (`xcode-select --switch` + `runFirstLaunch`), all of step 4
   and the `cmake_version`/`prefer_*` pins become unnecessary; the Ninja generator pin may stay
   (Ninja builds are faster and Xcode project generation is irrelevant to this hook).

First OpenCV compile takes a few minutes (FetchContent pulls the 4.13.0 tarball at configure; the
hook captures build output, so a silent run is a *good* sign). The Android arm64-v8a build is a
separate, equally long compile under the NDK toolchain — it does not reuse the macOS objects.

**Each runner gets its own poisoned hash.** The hook's shared build dir is keyed by config hash, and
`flutter test`, `flutter run/build`, and the plain `dart` runner (`dart run`/`dart test`) each
resolve a DIFFERENT hash for the same macos-arm64 target. Seeding one does not seed the others:
`dart run tools/omr_cli` failing with the same line-668 error after `flutter test` works means a
new `.dart_tool/hooks_runner/shared/dartcv4/build/<hash>` needs the same seeding (the exact
invocation — toolchain file, `-DPLATFORM=MAC_ARM64`, module toggles — is printed by
`dart run --verbose`; only `-B` and `-DCMAKE_INSTALL_PREFIX` change with the hash).
