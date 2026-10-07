# Releasing the Android app

## One-time: create the upload key

```bash
keytool -genkeypair -v -keystore ~/omr-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias omr-upload
```

Keep `omr-upload.jks` and its passwords somewhere safe (a password manager).
With Play App Signing, losing it means a support request to Google — not a
lost app — but treat it as a secret all the same. **Never commit it.**

## Local release builds

```bash
cp app/android/key.properties.example app/android/key.properties
# edit storeFile / passwords / alias
cd app
flutter build appbundle --release --target-platform android-arm64
```

Without `key.properties` the release build is signed with the **debug key**
(Gradle prints a warning). That is fine for testing on your own phone and
never acceptable for Play.

## CI releases (GitHub Actions)

Add four repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `OMR_KEYSTORE_BASE64` | `base64 -i ~/omr-upload.jks` (single line) |
| `OMR_KEYSTORE_PASSWORD` | keystore password |
| `OMR_KEY_ALIAS` | `omr-upload` |
| `OMR_KEY_PASSWORD` | key password |

Then, for each release:

1. Bump `version:` in `app/pubspec.yaml` (e.g. `1.1.0+2` — the `+N` build
   number must increase for every Play upload) and `kAppVersion` in
   `app/lib/src/version.dart` (a test keeps them in step).
2. Add a section to `CHANGELOG.md`.
3. Merge to `main` through a pull request.
4. Tag and push: `git tag v1.1.0 && git push origin v1.1.0`.

`.github/workflows/release.yml` checks the tag matches the pubspec version,
builds the `.aab` and an arm64 `.apk`, verifies 16 KB page alignment, and
attaches both to a GitHub Release. Upload the `.aab` in Play Console.

## Before the first Play upload

- `applicationId` (`com.projx.omr.omr_app` in
  `app/android/app/build.gradle.kts`) is permanent once published — change it
  now if you want a different identity.
- Replace the default launcher icon (`app/android/app/src/main/res/mipmap-*`).
- Play's Data safety form: all data stays on the device; the camera is used
  only to photograph answer sheets; no data is collected or shared.
- Only arm64 builds are produced (see `docs/m0-gate.md` for the x86_64
  OpenCV caveat); this covers essentially every Android phone sold since 2019.
