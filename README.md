# projX — OMR Evaluator

[![CI](https://github.com/ManoharPaturi/projX/actions/workflows/ci.yml/badge.svg)](https://github.com/ManoharPaturi/projX/actions/workflows/ci.yml)

Android app (Flutter) that marks bubble answer sheets for coaching institutes
and schools: print the sheet, photograph it with the phone, get marks
instantly — **fully offline**, with every doubtful sheet sent to a quick human
check instead of being silently mis-marked.

**For operators:** read the [user guide](docs/user-guide.md) (also in the app
under *Menu → How to use*).

## What it does

- **Guided setup** — a getting-started checklist walks a first-time user from
  an empty phone to the first marked sheet.
- **Printable sheets** generated from one spec, so print and reader can never
  disagree; roll numbers carry a check digit.
- **Auto-capture scanner** — live coaching (move closer, hold still, too dark,
  glare) and a hands-free shutter.
- **On-device reading** with OpenCV and a confidence score per bubble; faint,
  double-marked or unreadable sheets go to **Sheets to check**.
- **Marking schemes as data** — NEET/JEE Main (+4/−1/0), JEE Advanced
  multi-correct with partial marks, NTA key-correction states.
- **Answer-key fixes re-mark everything** from stored reads — no rescanning;
  every key version is kept for audit.
- **Results, analysis and reports** — ranks, subject averages, hardest
  questions, likely key mistakes; class PDF, Excel, CSV and per-student
  marksheets (Indian-script names supported), shared via any app.
- **Privacy first** — roll numbers as identity, names optional, data never
  leaves the phone; full-size photos auto-deleted after a grace period.

## Layout

| Path | What |
|---|---|
| `packages/omr_spec` | Sheet spec (single source of truth, mm) → print PDF + detection template |
| `packages/omr_core` | Grading engine (scoring strategies, key versioning, re-grade) — pure Dart |
| `packages/omr_detect` | OpenCV detection pipeline + capture gates — only package touching opencv_dart |
| `packages/omr_data` | drift/SQLite schema + DAOs (tenant-leading) |
| `packages/omr_reports` | PDF/XLSX/CSV renderers over one canonical results query |
| `app/` | Flutter app (capture scanner, review queue, results, analytics) |
| `tools/omr_cli` | Headless: render sheets, emit templates, golden corpus, accuracy harness |
| `docs/` | Research digests, spec format, calibration SOP, milestone gate records |

Design + research: see `docs/plan.md` and `docs/research/`.

## Quality gates

Every pull request runs format + analyze, all package suites (incl. an
OpenCV smoke probe), the app's widget/flow tests, and an arm64 APK build
checked for Play's 16 KB page alignment. `main` only moves through merged,
green pull requests.

## Getting started (developers)

Requires Flutter 3.47 / Dart ≥ 3.10, JDK 17 for Android
(`flutter config --jdk-dir=…`), and CMake + Ninja for the OpenCV build.

```bash
flutter pub get                       # at repo root (pub workspace)
(cd packages/omr_core && dart test)   # pure-Dart suites run in seconds
(cd app && flutter test)              # first run compiles OpenCV (~20 min)
(cd app && flutter run)               # on an arm64 Android phone/emulator
```

The full check list CI runs is in [CONTRIBUTING.md](CONTRIBUTING.md); first
OpenCV build notes are in [docs/m0-gate.md](docs/m0-gate.md). Releases:
[docs/release.md](docs/release.md).

## Rendering sheets (no phone needed)

```bash
dart run tools/omr_cli pdf      --preset A --out build/std90.pdf
dart run tools/omr_cli template --preset B --summary
dart run tools/omr_cli spec     --preset A --hash
```

- **Preset A — Standard-90**: 90 questions, 3 columns, 5.0×3.5 mm bubbles
  at 7.6/7.8 mm pitch. MVP default; comfortable detection geometry.
- **Preset B — NEET-180**: 180 questions, 4 columns, 4.0×3.0 mm bubbles at
  5.7 mm pitch (real-NEET density). Capture gate demands ≥2400 px across the
  sheet — any modern 12 MP phone qualifies.

Every preset is validated at build time (`validateSheetSpec`) against the
layout physics (margins ≥10 mm, pitch ≥1.4× bubble major axis, fiducial/QR/
timing-track clearances, block extents inside the content rect), so a layout
typo fails loudly instead of printing.

## The single-source-of-truth rule

A sheet layout is authored **once** in mm (`packages/omr_spec`). Two compilers
consume it — `compileSheetPdf` (print) and `compileDetectionTemplate`
(detection grid, 8 px/mm on a 1680×2376 canvas) — and both take their page
geometry from the same `LayoutGeometry`. Template-vs-print drift is therefore
impossible by construction. `specHash = sha256(canonicalJson(spec))` is stored
with every layout row and re-verified at load; the QR printed on each sheet
encodes `OMR1:<layoutId>:v<layoutVersion>`, so a 2026 print run still grades
correctly in 2030.
