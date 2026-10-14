# Changelog

All notable changes to the OMR Evaluator app. Versions match `version:` in
`app/pubspec.yaml`.

## 1.0.0 — unreleased

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
- Exams with several sets (A–D) are marked against each student's own
  set; previously every student was marked against one set's key.
- A second sheet with the same roll number goes to review instead of
  being silently ignored; a confirmed rescan replaces the earlier sheet.
- Fixing one problem on a sheet no longer hides its other problems; set
  bubbles can be corrected in review and the correction is used for marks.
- "Retake photo" no longer leaves a sheet stuck as needing review; blurry
  or curled sheets can be accepted with "Sheet looks right — mark it".
- "Calculate marks" with nothing ready no longer marks the exam as done;
  exams show "In progress" while being scanned.
- Pasted rolls that cannot be bubbled are listed instead of silently
  accepted; the data-retention setting accepts only 1–365 days.
- A sheet waiting for a check no longer shows a score after scanning.
- PDFs leave out the exam date line when there is no date.
- Reports say OK / Check sheet / Re-marked instead of internal codes.
- Shared files are named after the exam (e.g. `Mock 1 - Class results
  (key 1).pdf`) instead of `csv-v1.csv`.

- The Excel workbook now includes the Per Question sheet (every student's
  marks on every question) that its description promised.

### Performance
- Reading a sheet: 12 MP photo from ~7.5 s to ~0.2 s on the benchmark;
  detection and the live preview run off the UI thread, so the screen no
  longer freezes while a sheet is read.
- Marking after each sheet takes the same time for a class of 10 or 500.
- Smaller app (unused OpenCV modules removed); faster start-up.
- Class PDF / Excel / CSV are built in the background.

### Dependencies
- drift_dev 2.35.1; GitHub Actions checkout v7.
