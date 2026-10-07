# Changelog

All notable changes to the OMR Evaluator app. Versions match `version:` in
`app/pubspec.yaml`.

## 1.0.0 — 2026-10-07

First production release.

### Added
- Getting-started checklist on the home screen; "How to use" help screen.
- Print answer sheets from the exam page (hash-verified layout, print tips).
- Add / remove individual students; paste lists straight from spreadsheets.
- Check digit shown for every student; unscannable rolls flagged.
- "Whose sheet is this?" in review: attribute a sheet whose roll number
  could not be matched, so it can be marked.
- Analysis tab: class summary, score spread, subject averages, hardest
  questions with option split, likely answer-key mistakes.
- Editable institute name; dark mode; Android app name "OMR Evaluator".
- Offline Indian-script fonts in PDF marksheets and class lists (uses the
  phone's own Noto fonts).
- Release signing via `key.properties` / CI secrets; tag-driven release
  workflow producing a Play bundle and APK.
- CI on every pull request: format, analyze, all suites, arm64 APK with
  16 KB alignment check.

### Changed
- Plain-language wording on every screen (no internal codes or ids).
- Saving a corrected answer key re-marks existing sheets automatically.
- Developer fixture buttons are hidden in release builds.

### Fixed
- Sheets bubbled with leading zeros (`0001234`) now match roster roll
  `1234`; previously they were stuck in review and never marked.
- Answer-key set tabs now switch the question grid.
- Institute-name dialog no longer crashes while closing.
- Machine-specific JDK path removed from the Android build.
