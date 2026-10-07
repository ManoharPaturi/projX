# Contributing to projX

## Workflow

1. Branch from `main` (`feature/…`, `fix/…`, `phase-N/…`).
2. Keep the change focused; one concern per pull request.
3. Open a PR — CI must be green before merge. `main` only moves through
   merged pull requests, never direct pushes.

## Local checks (what CI runs)

```bash
flutter pub get                                    # workspace root
dart format app/lib app/test packages/*/lib packages/*/test tools/omr_cli
flutter analyze
(cd packages/omr_spec    && dart test)
(cd packages/omr_core    && dart test)
(cd packages/omr_data    && dart test)
(cd packages/omr_reports && dart test)
(cd packages/omr_detect  && flutter test)          # first run compiles OpenCV
(cd app                  && flutter test)
```

Run package suites one at a time — two concurrent `dart test` runs race on
the shared native-assets build directory and fail spuriously.

Android builds need JDK 17: `flutter config --jdk-dir=<JDK 17 home>` (or
`JAVA_HOME`). Never commit machine paths into `app/android/gradle.properties`.

The first OpenCV build on macOS needs the toolchain notes in
[`docs/m0-gate.md`](docs/m0-gate.md).

## Code rules that matter here

- **The sheet spec is the single source of truth.** Never hand-edit detection
  geometry; change `packages/omr_spec` and let both compilers derive from it.
- **Answer keys and layouts are immutable.** Edits insert a new version; a
  re-grade is an insert, never an UPDATE.
- **All OpenCV calls go through `OpencvService`** in `omr_detect`.
- **Operator-facing text is plain language.** No internal codes, enum names,
  or IDs in the UI — see `docs/user-guide.md` for the voice.
- Regenerate drift code after schema changes:
  `cd packages/omr_data && dart run build_runner build`.
