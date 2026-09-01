# projX — OMR Sheet Evaluation System

Mobile (Android-first, Flutter) OMR grading for coaching institutes: capture sheets
with the phone camera, detect bubbles **on-device** (offline), grade against
versioned answer keys, and generate marksheets/reports.

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

## Getting started

```bash
dart pub get          # at repo root (workspace)
dart test             # all pure-Dart packages
cd app && flutter run # Android device
```

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
