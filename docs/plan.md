# OMR Sheet Evaluation System — Mobile (Android-first, Flutter)

## Context

We are building (greenfield — `~/Desktop/projX` is empty) a robust OMR (Optical Mark Recognition) system for Indian coaching institutes/schools:

1. **An Android app** (Flutter, iOS later) that captures OMR sheets with the phone camera, detects marked bubbles **entirely on-device**, grades them against an answer key, and generates reports/marksheets — no internet required (exam halls have poor connectivity).
2. **Our own printable OMR sheet** (PDF), designed specifically for reliable detection by our software — registration fiducials, timing track, bubbled roll-number field, QR sheet ID.
3. **A multi-tenant product trajectory**: MVP is app-first/local-only, but the data model is tenant-ready from day one; cloud sync (Supabase) is a later phase.

The central technical fact driving the design: the best open-source reference (OMRChecker, MIT) achieves ~100% accuracy on flatbed scans but only **~90% on phone photos**. The gap is capture-bound, not algorithm-bound. Therefore the product bets on: (a) sheets designed for detectability, (b) a live capture-quality gate, and (c) a confidence-scored **human review queue** that turns ~90% into ~99%+.

Research completed via 9 research agents (~730K tokens); digests preserved at `/tmp/omr_digest_short.txt` (summaries/recs/risks) and `/tmp/omr_research_full.txt` (+facts/source URLs). Copy these into the repo (`docs/research/`) when implementation starts — they hold the tuning constants and license notes.

## Locked decisions (confirmed with user)

| Decision | Choice |
|---|---|
| App stack | **Flutter** (single codebase; iOS port later; detection+grading+PDF-gen never drift across platforms) |
| Evaluation | **On-device, offline-first** (OpenCV on phone) |
| Scale model | **Multi-tenant product** later; MVP app-first, local-only, tenant-ready schema |
| Reports | PDF marksheets (per-student + consolidated), Excel/CSV export, in-app analytics, share via WhatsApp/share sheet |
| Capture UX | **Auto-capture scanner** — live overlay, auto-shutter when steady/flat, instant grade + confidence check |
| Market patterns | JEE/NEET-style: 50–200 MCQs, 4 options, roll-number bubbles, answer-set codes (A/B/C/D), negative marking |

---

## 1. Repo / Package Structure

Dart **pub workspace** (root `pubspec.yaml` with `workspace:`; needs Dart ≥3.10, which opencv_dart's Native Assets requires anyway). Pure-Dart cores are Flutter-free so tests run in milliseconds on host.

```
projX/
  pubspec.yaml                  # workspace root
  packages/
    omr_spec/                   # PURE DART — sheet spec: schema, validation, compilers
      lib/src/models/           # sheet_spec.dart, field_block.dart, bubble_style.dart,
                                #   fiducial.dart, timing_track.dart, qr_zone.dart, section.dart
      lib/src/schema/           # JSON validator (additionalProperties:false, like OMRChecker's)
      lib/src/compile/
        detection_template.dart # SheetSpec → DetectionTemplate (canvas-px geometry)
        pdf_sheet_compiler.dart # SheetSpec → pw.Document (vector, mm units)
      lib/src/builders/         # jee_style_sheet.dart — parametric variant builders
      test/
    omr_core/                   # PURE DART — grading engine, result/confidence models. Zero IO.
      lib/src/grading/          # scoring_strategy.dart + single_correct / multi_correct_partial /
                                #   integer_digits / matrix_match / key_correction_override
                                # scoring_presets.dart (NEET/JEE-Main {4,−1,0}, JEE-Adv multi)
      lib/src/models/           # marked_response, key_entry, question_outcome, exam_result,
                                #   sheet_read, confidence
      lib/src/diagnostics/      # wrong_key_detector.dart (post-grade heuristics)
      test/
    omr_detect/                 # OpenCV pipeline — the ONLY package importing opencv_dart
      lib/src/cv/               # opencv_service.dart (abstract) + opencv_dart_impl.dart
      lib/src/pipeline/         # stage classes + pipeline.dart orchestrator (see §3)
      lib/src/thresholds/       # threshold_config.dart (MIN_JUMP family, versioned JSON)
      lib/src/capture/          # quad_detector.dart, quality_gates.dart, hysteresis.dart
      test/ + testdata/golden/  # golden-image harness fixtures
    omr_data/                   # drift schema + DAOs (pure Dart; sqlite3 FFI for host tests)
      lib/src/tables/  lib/src/daos/   # scans/results/review/analytics DAOs
      lib/src/app_db.dart       # drift Database; beforeOpen: foreign_keys=ON, WAL
      lib/src/migrations/
      lib/sync/                 # sync_outbox model + NO-OP transport (phase-2 seam)
    omr_reports/                # PURE DART renderers over omr_data/omr_core models
      lib/src/results_query.dart        # the ONE canonical results SELECT → ReportRow stream
      lib/src/{marksheet_pdf, consolidated_pdf, excel_export, csv_export, annotated_overlay}.dart
  app/                          # Flutter UI (Android-first)
    lib/features/               # dashboard, exams, keys, students, sheet_print, capture,
                                #   review, results, analytics, reports, calibration, settings
    integration_test/           # on-device opencv_dart smoke + capture gates (M0 gate)
  tools/omr_cli/                # dart run: render sheet PDF, emit detection template JSON,
                                #   build golden corpus, run accuracy harness headless
  docs/                         # research digests, spec format doc, calibration SOP, m0_gate.md
```

Key structural choices:
- **`OpencvService` abstraction inside `omr_detect`** — every `cv.*` call goes through ~15 methods (`cvtColor, matchTemplate, getPerspectiveTransform, warpPerspective, mean, Laplacian, morphologyEx, findContours, normalize, …`). This is the firewall against opencv_dart's single-maintainer risk AND the seam where a native Kotlin implementation of the live quad loop can be swapped in without touching pipeline code.
- **`tools/omr_cli`** — calibration and golden-corpus workflows run on the dev machine, not the phone.

**Pinned deps** (exact, no `^`): `opencv_dart 2.2.2` (enable modules `core,imgproc,imgcodecs,calib3d` in native-assets config), `camera 0.12.x` (decide vs `camerawesome 2.5.0` in M0), `pdf 3.13.0`, `printing 5.15.0`, `excel_plus 2.16.0`, `csv 8.0.0`, `drift 2.34.3`, `share_plus 13.3.0`. Flutter ≥3.38 / Dart ≥3.10.

## 2. Sheet Spec Format (single source of truth — a core deliverable)

Authored in **mm**; two compilers consume it: `pdf_sheet_compiler` (print) and `detection_template` (canvas px). Neither is ever edited independently — enforced by `specHash` stored with every layout row and re-verified at load. QR encodes `layoutId + layoutVersion`; detection refuses a version it can't resolve; old printed sheets grade correctly forever.

### Field list

| Field | Type | Notes |
|---|---|---|
| `specVersion` | int | Schema version; bump = migration code |
| `layoutId` / `layoutVersion` | string / int | Immutable once printed; encoded in QR |
| `paper` | `{size:"A4", orientation:"portrait"}` | A4 portrait in v1 |
| `marginMm` | ≥10 all sides | Fiducials inset inside margin |
| `bubbleStyle` | `{shape:"oval", wMm, hMm, strokeMm:0.25, pitchMm, outlineColor:"#D64000", labelColor:"#D64000"}` | Drop-out orange; thin strokes; pitch 1.4–1.5× major axis |
| `fiducials` | `{shape:"square", sizeMm:9.0, insetMm:12.0, whiteSurroundMm:3.5, corners:[tl,tr,br], altAnchor:"bl_L"}` | 3 identical squares + 1 distinct L at bottom-left ⇒ unambiguous orientation. Black only |
| `timingTrack` | `{edge:"left", barMm:{w:5.5,h:2.5}, clearanceMm:5.0, perRowBand:true}` | One black bar per row-band (shared row grid). Redundant registration + curvature residual check |
| `qrZone` | `{sizeMm:16, position:"tr", ecc:"M", quietZoneModules:4, payload:{layoutId,layoutVersion,checksum}}` | Black; template identity is authoritative |
| `serialZone` | `{edge:"bottom"}` | Human-readable serial, black |
| `fieldBlocks[]` | see below | Additive geometry (OMRChecker-proven) |
| `sections[]` | `{id, name, subject, questionIds[], maxCounted?}` | `maxCounted` = N-of-M (NEET Section II) |
| `rollField` | ref to roll block + `{digits:7, checksum:true}` | Checksum digit; validated against roster |
| `setField` | ref to set block + `{values:["A","B","C","D"]}` | Bubbled set code |

### `fieldBlock` — additive geometry, no per-bubble coordinates ever stored

```json
{
  "blockId": "mcq_col1",
  "blockType": "MCQ",            // MCQ | INT_DIGITS | ROLL_DIGITS | SET_CODE | MATRIX
  "originMm": [24.0, 42.0],
  "bubblePitchMm": 7.6,          // advances along the option axis
  "rowPitchMm": 7.8,             // advances along the field axis
  "direction": "vertical",       // fields stack vertically, options run horizontally
  "options": 4,                  // MCQ4 (use 5 for MCQ5); bubbleValues 0-9 for digit blocks
  "fieldLabels": ["q1..q30"]     // range-expandable
}
```

Block extent is computed (`pitch*(count-1)+bubble`) and **validation rejects any block overflowing the content rect at load time** — this catches layout typos before they print (this exact check would have caught a 45-row/landscape mistake made during design; real NEET-180 sheets fit only at ~5.5mm pitch).

### Sheet presets (built, not hand-authored — `builders/jee_style_sheet.dart`)

Geometry must satisfy the validator; both presets fit portrait A4 (210×297, ~10mm margins, ~25mm header):

| Preset | Layout | Geometry |
|---|---|---|
| **A: Standard-90** (MVP default) | 3 columns × 30 rows + roll + set code | 5.0×3.5mm ovals, pitch 7.6/7.8mm (comfortable detection) — width ≈ 3×(4×7.6+10)=121mm ✓, height 30×7.8=234mm ✓ |
| **B: NEET-180** (dense) | 4 columns × 45 rows + roll + set code | ~4.0×3.0mm ovals, pitch ~5.5mm (the vendors' dense-but-valid zone; real NEET sheets do exactly this) — height 45×5.5=248mm ✓ |

Notes: changing anything geometric bumps `layoutVersion`; colors/instruction text don't. Preset B's smaller bubbles raise the capture-resolution floor (≥40px/bubble ⇒ ≥10px/mm ⇒ ≥2100px across the sheet) — still fine on any modern 12MP phone, and the capture gate enforces it per preset.

### Canonical detection canvas (compiled, not authored)

`PX_PER_MM = 8.0` → Preset A bubble major axis = **40px** (OMRChecker's proven size), pitch 7.6mm → 61px (OMRChecker: 59). Portrait A4 → **1680×2376 px** canvas.

## 3. Detection Pipeline

Runs in a **dedicated isolate** on the full-res still — never on live frames. Each stage is a class with `StageOutput call(StageInput)` so the harness attributes errors per stage.

| # | Stage | OpenCV calls & constants | In → Out |
|---|---|---|---|
| 0 | `BurstSelector` | Laplacian variance on Y-plane (downscaled 320px long side) over 3–5 YUV frames; keep sharpest whose quad matches | frames → 1 still |
| 0b | `GateRevalidator` | re-run all five capture gates on the **selected** frame | still → pass/retake |
| 1 | `StillLoader` | decode, EXIF-rotate, `cvtColor(GRAY)` | bytes → `StillImage` |
| 2 | `FiducialRegistrar` | `matchTemplate(TM_CCOEFF_NORMED)` per quadrant (quadrant separators so a match can't straddle a midline), scale sweep **35%→100% in 10 steps**; accept quadrant ≥**0.3**, reject if score deviates ≥**0.41** from global best; marker = 1/17 sheet width | image + template → 4 fiducial centers + 4 scores |
| 3 | `HomographyWarper` | `getPerspectiveTransform` (4 centers → canvas corners) + `warpPerspective` → 1680×2376 | image → warped canvas |
| 4 | `CurvatureResidualGate` | project each timing-bar centroid vs expected grid position; residual RMS > **0.30 × bubble height** ⇒ curl flag | warped → residual report |
| 5 | `ChannelSelector` | per-channel bubble-mean bimodality on sampled strips; pick channel where drop-out ink is weakest (green/blue for orange); HSV-ratio fallback vs AWB drift | warped → single-channel mat |
| 6 | `BubbleReader` | `mean()` over inner **70%** of each bubble ROI (avoids the 0.25mm stroke); morphology copy for stray-mark detection: `CLAHE(clip 5.0, tile 8×8)` on the **morphology copy only**, `2×10 vertical opening` + `5×5 erode`, morph threshold 60 (camera) / 40 (scan) | mat + template → meanIntensity, fillRatio, strayMark |
| 7 | `ThresholdEngine` | **Two-tier largest-gap**: global = sort all bubble means, first gap with looseness 4 (fallbacks: white 200 / black 100); per-strip = largest adjacent gap, confident jump = **MIN_JUMP 25 + CONFIDENT_SURPLUS 5 = 30**; strip falls back to global if <3 values or spread ≤ **MIN_GAP 30**; strip std > global std ⇒ strip distrusted (all-black/all-white) | bubble means → thresholds |
| 8 | `BubbleClassifier` | three-zone: `fillRatio < emptyMax` → EMPTY; `> filledMin` → FILLED; between → **PROBABLE**; emits `markClass ∈ {FILLED, EMPTY, PROBABLE, MULTIPLE, OVERFILLED, BLANK}` (Addmen taxonomy); **unmarked-row floor** (never argmax); multi-mark detection | reads → classified reads |
| 9 | `FieldDecoder` | roll digits: exactly-1-per-column else flag; blank column vs explicit `0` distinguished; set code; integer blocks (right-aligned, leading-zero semantics); roll checksum + roster validation | reads → `SheetRead` |
| 10 | `ConfidenceAggregator` | model below | → per-bubble/per-field/per-sheet confidence |
| 11 | `SheetResolver` | QR decode → layoutId+version (authoritative; fallback = exam's bound layout); persists warped grayscale + annotated thumbnail; drops 12MP original after grace window | → `SheetReadResult` |

**Confidence model** (numeric, first-class, stored):
- `bubbleConf = clamp01((|mean − stripThreshold| − band)/band) × (1 − strayPenalty)`; band from MIN_JUMP family.
- `fieldConf = min(bubbleConf)` over the field, −0.25 per PROBABLE, −0.5 per MULTI.
- `sheetConf = min(0.95, fiducial scores, 1 − timingResidual/tol, median fieldConf)`.
- **Routing**: any PROBABLE → review; `sheetConf < 0.90` → review; roll checksum/roster mismatch, blank or multi-marked set code → **mandatory** review; curl flag → review with manual corner-drag offered.

**Fallback ladder** (degrade, never fail silently):
1. Quadrant fiducial matching (primary).
2. Any quadrant failed → re-search that corner unrestricted + alternate **L-corner** template; take higher score.
3. Both fail → **timing-track least-squares affine** (skew/scale only) ⇒ proceed flagged low-confidence.
4. Else → reject-to-review with reason code (`NO_MARKER_ERR`, `MULTI_BUBBLE_WARN`, …) keeping the unwarped image, so a human can corner-drag in review and re-run stages 3–10.

**Capture loop** (live, ~640×480 analysis stream; overlay only — bubbles never read here):
- Quad detection: downscale 480px → gray → `GaussianBlur(5,5)` → `THRESH_TRUNC 150` → `Canny(85,185)` → `THRESH_TOZERO 155` → `MORPH_CLOSE 10×10` → `findContours` → hull → `approxPolyDP(0.02×perimeter)` → first 4-point hull; corners ordered by min/max(x+y), min/max(y−x).
- **Five gates**: area 0.20–0.95× preview (<0.25 "move closer", >0.75 or touching edge "move away"); max interior-angle cosine < **0.085**; blur = Laplacian variance at 320px inside quad, firing on **rolling 75th-percentile relative test** (calibration-free) with absolute floor per strictness preset (Strict/Normal/Relaxed); exposure mean 60–200 (midpoint 110–140); glare = region-relative (contiguous region > k× surrounding-zone mean + near-zero HSV saturation); resolution gate `quadShortSidePx / analysisWidth ≥ requiredPxPerSheetShortSide / stillWidth`.
- **Hysteresis auto-capture** (WeScan constants): 8-quad rolling queue, min 3, **6px** corner consensus, **35** stable passes, reset after 3 misses; progress ring; manual shutter always; audio cue.
- YUV burst of 3–5 frames on trigger (never JPEG burst — ~243ms/frame stalls); lock AE/AF; torch off by default, offered only after 1.5s under-exposure with "tilt 30–45°" instruction.
- Live loop runs behind the `EdgeAnalyzer` interface; if a 640×480 frame exceeds the ~32ms budget on the low-end device (measured at M0/M2), swap in a Kotlin platform channel — pipeline code untouched.

## 4. Data Schema (drift / SQLite)

Every domain table carries `tenantId` as the **leading column**, indexed tenant-first. `†` = exists now for phase-2 sync, unused in MVP.

```sql
tenants(id TEXT PK, name, plan, createdAt)                         -- MVP: exactly one row
institutes(id TEXT PK, tenantId †, name, code, createdAt, syncState †)
students(id TEXT PK, tenantId †, instituteId FK, rollNo, name NULLABLE /*PII-min*/,
         batch, createdAt, UNIQUE(instituteId, rollNo))
sheet_layouts(id TEXT PK, tenantId †, layoutId, layoutVersion INT, specJson, specHash,
              createdAt, isActive, UNIQUE(layoutId, layoutVersion))
exams(id TEXT PK, tenantId †, instituteId FK, name, heldAt, sheetLayoutId FK,
      totalQuestions, status /*draft|active|graded|published*/, gradingConfigJson, createdAt)
question_sets(examId FK, setCode, questionMapJson /*sheet ordinal → canonical qId*/)
scoring_rules(id TEXT PK, tenantId †, name, strategy /*enum*/, paramsJson)
answer_key_versions(id TEXT PK, examId FK, version INT, status /*provisional|final*/,
                    supersedesId NULLABLE, createdBy, createdAt)   -- NEVER updated in place
answer_key_entries(keyVersionId FK, setCode, questionId, correctOptionsJson, correctInteger,
                   state /*normal|multiple_correct_key|all_options_correct|none_correct|dropped*/,
                   scoringRuleId NULLABLE, PK(keyVersionId, setCode, questionId))
scans(id TEXT PK /*client UUID at capture — idempotency key †*/, tenantId †, examId FK,
      studentId NULLABLE FK, rollNoRead, rollConfidence, setCodeRead, layoutVersion,
      thresholdConfigId, capturedAt, deviceId †, warpedImagePath, thumbPath, annotatedPath,
      originalPath NULLABLE /*retention-managed*/, sheetConfidence REAL, gateReportJson,
      curlFlag INT, status /*graded|needs_review|reviewed|rejected*/, syncState †,
      UNIQUE(examId, id))
bubble_reads(scanId FK, fieldKey /*q17|roll3|set*/, optionIndex, meanIntensity REAL,
             fillRatio REAL, markClass, confidence REAL, thresholdUsed REAL,
             isHumanCorrection INT DEFAULT 0, PK(scanId, fieldKey, optionIndex))  -- re-grade substrate
results(id TEXT PK, scanId FK, examId FK, studentId FK, keyVersionId FK, scoringRunId,
        total REAL, correct, wrong, unattempted, subjectTotalsJson, rank NULLABLE,
        status /*ok|doubtful|regraded*/, gradedAt, UNIQUE(examId, studentId, keyVersionId))
scoring_runs(id TEXT PK, examId, keyVersionId FK, scoringRuleSnapshotJson,
             sheetLayoutVersion, thresholdConfigId, startedAt, finishedAt)  -- full audit
review_queue(id TEXT PK, scanId FK, reasonCode, fieldRefsJson, severity,
             resolvedBy NULLABLE, resolvedAt NULLABLE, correctionJson, outcome)
report_jobs(id TEXT PK, examId FK, type /*marksheet|consolidated|excel|csv|analytics*/,
            format, paramsJson, filePath, status, generatedAt, errorText NULLABLE)
audit_log(id TEXT PK, entity, entityId, action, beforeJson, afterJson, at, byUser)
sync_outbox †(id TEXT PK, tableName, rowId, op, payloadJson, attempts, lastAttemptAt)
```

`beforeOpen`: `PRAGMA foreign_keys = ON;` `PRAGMA journal_mode = WAL;`. Analytics (ranks via `RANK() OVER`, subject cutoffs, difficulty/discrimination index, distractor distribution) are drift window queries in `analytics_dao.dart` — never app-side loops.

## 5. Grading Engine (`omr_core`)

```dart
abstract class ScoringStrategy {
  QuestionOutcome score(MarkedResponse r, KeyEntry k, ScoringParams p);
}
// SingleCorrectStrategy, MultiCorrectPartialStrategy, IntegerDigitsStrategy,
// MatrixMatchStrategy, KeyCorrectionOverrideStrategy
```

- **Marking is data**: `scoring_rules` rows select strategy + params; per-question override falls back to section default; no switch statements in app code. Presets: `NEET_JEE_MAIN {correct:4, wrong:−1, unattempted:0}`; `JEE_ADV_MULTICORRECT {full:4, partialByCount:{1:1,2:2,3:3}, anyWrong:−1, unattempted:0}` (legacy `anyWrong:−2` as another row — the penalty changed year to year).
- **`multiMarkAction` is per-question-type config** (`invalid | wrong | zero`) — never a global rule.
- **Partial credit = pure set function** on chosen set `C` vs key set `K`: `C=∅` → 0; `C=K` → full; `C⊂K` strict → `partialByCount[|C|]`; any element of `C ∉ K` → `anyWrong`. Guard: `|K|==1` ⇒ choosing it is full, not partial. Unit test pins the official JEE-Adv worked example (`K={A,B,D}`: {A,B,D}→+4, any pair→+2, {A}→+1, ∅→0, anything with a wrong option→−1).
- **Key-correction states** (NTA rules, first-class): `multiple_correct_key` → +4 to all who marked any correct option; `all_options_correct` → +4 to all who attempted; `none_correct`/`dropped` → +4 to all regardless of attempt. Applied via `KeyCorrectionOverrideStrategy` after the base strategy.
- **N-of-M sections**: `sections.maxCounted` — first N valid responses in sheet serial order; extras ignored without penalty.
- **Re-grade flow**: edit key ⇒ *insert* new `answer_key_versions` row (supersedes old) ⇒ new `scoring_runs` ⇒ recompute all results from `bubble_reads` + `isHumanCorrection` overlays (human corrections supersede raw reads, deterministically) ⇒ new `results` rows. No UPDATE, no rescan. Historical marksheets reproduce exactly via the `scoring_runs` snapshot.
- **Wrong-key detector** (post-grade heuristics): flag questions with near-zero cohort correct-rate, correct-rate collapsing vs difficulty index, or unusually high multi-mark rate → advisory cards on the key editor.

## 6. App Screens / Flows

1. **Dashboard** — recent exams, capture CTA, pending-review badge, storage indicator.
2. **Exam setup** — pick layout from the generated spec library, define sections/sets, bind grading preset.
3. **Key editor** — per-set tabs (A/B/C/D), grid entry, key-correction state per question, version history, wrong-key advisories, "publish as final" (immutable).
4. **Students** — roster CSV import (BOM-tolerant), roll numbers + optional names, duplicate detection.
5. **Sheet print** — preview + generate PDF + print (`printing`); records the `layoutVersion` for the run.
6. **Capture scanner** — fixed A4-aspect finder frame + animated quad overlay (green only when all gates pass), coach hints in priority order (move closer/away, adjust angle, hold still + progress ring, too dark, glare→tilt, plainer background), auto-shutter on hysteresis completion, manual shutter always, audio cue; post-capture card shows roll, set, score, per-sheet confidence with a green/amber chip.
7. **Review queue** — sorted by reason code (roll invalid, set invalid, multi-mark, PROBABLE bubbles, low confidence, curl); tap-through shows the **zoomed warped crop** beside the read values; operator taps the correct bubble or types roll digits; correction writes `bubble_reads.isHumanCorrection=1`; ~5–10s per sheet → effective accuracy ~99%+.
8. **Results** — list with ranks; student detail = per-question table + annotated sheet image.
9. **Analytics** — subject-wise means, rank/percentile, difficulty & discrimination index, distractor distribution.
10. **Reports/Export** — pick exam + key version → marksheet PDF / consolidated PDF / XLSX / CSV; share sheet.
11. **Calibration** — see §9.
12. **Settings** — threshold presets (Strict/Normal/Relaxed), torch policy, retention policy, institute/tenant info.

## 7. Reports

One canonical source: `ResultsQuery(examId, keyVersionId)` → `Stream<ReportRow>` (student ⋈ scan ⋈ result ⋈ layout; per-question detail lazy). Every renderer consumes only `ReportRow`s.

- **Per-student marksheet PDF** — `pdf` single `Page`: header (roll, exam, date), score summary block, per-question table with verdict glyphs, annotated crop footer. TTF embedded with `fontFallback` for Indian scripts.
- **Consolidated class PDF** — `MultiPage` + `pw.Table`, repeating header row, `maxPages` raised to **500** (default 20 throws at ~200 students).
- **XLSX** — `excel_plus 2.16.0`; summary + per-question sheets; formulas for rank/percentile so institutes can extend.
- **CSV** — `csv 8.0.0` streaming `StreamTransformer` (10k-row safety), **UTF-8 BOM** for Indian-language names, `asCodec()` (v8 breaking change).
- **Share** — files in app-documents dir; `SharePlus.instance.share(ShareParams(files:[...], fileNameOverrides:[...]))`. WhatsApp = best-effort via share sheet (never promised in UI copy); bulk delivery is a phase-2 WhatsApp Cloud API concern.
- Every generation writes a `report_jobs` row (params + path) — exports traceable/reproducible.

## 8. Milestones

| M | Scope | Acceptance criteria (verified by) |
|---|---|---|
| **M0** | Workspace scaffold; `omr_spec` v1 (schema + Preset A/B builders + PDF compiler); **opencv_dart smoke test**; 16KB check | (a) `dart test` green across all packages. (b) Preset A & B PDFs print; compiled `DetectionTemplate` geometry equals PDF geometry by construction (asserted in test; validator rejects overflow). (c) **Go/no-go gate**: `integration_test/smoke_test.dart` on a real **arm64 Android device** exercises `cvtColor, matchTemplate, getPerspectiveTransform, warpPerspective, mean, Laplacian` (calib3d enabled) and times a 640×480 quad-detect frame. (d) `zipalign -c -P 16` passes on the APK. **Native-fallback decision**: any missing/broken symbol, or timed frame >~32ms on the low-end device, or 16KB failure ⇒ keep Flutter UI/spec/reports, port the live quad loop to a Kotlin platform channel behind `EdgeAnalyzer` (opencv_dart still serves the still pipeline). Recorded in `docs/m0_gate.md`. |
| **M1** | `omr_detect` full pipeline; golden-image harness; threshold config JSON | On the synthetic golden corpus (§9): **100% field-exact reads on clean renders**, ≥98% under the perturbation suite; fallback ladder covered by tests (occluded corner → L-corner; both fail → reject with reason code); curvature gate fires on synthetic curl. Runs headless via `tools/omr_cli` + `dart test`. |
| **M2** | Capture UX (gates + hysteresis + burst), grading engine, drift schema, review queue; end-to-end | On-device: scan a printed sheet ⇒ graded result in <3s incl. isolate hop; deliberate bad captures (glare, tilt, blur, partial frame) each produce the correct coach hint; multi-marked and faint-mark sheets land in the review queue and are correctable in ≤10s; re-grade from a corrected key produces new results with no rescan (integration test). Low-end device (2–4GB) frame-analysis time recorded against the M0 number. |
| **M3** | Reports, exports, analytics, share | All four outputs generated from one exam in <30s for 200 students; consolidated PDF paginates past 20 pages without throwing; CSV opens in Excel with Devanagari names intact; share delivers to WhatsApp/Gmail on Android 11+. |
| **M4** | Pilot hardening: printer-calibration flow, real-photo accuracy harness, retention job, audit log | Calibration SOP run on 2 different printers + 2 photocopy generations with margin report; accuracy on ≥150 real phone photos ≥99% after review (per-stage attribution published); scripted tenant-schema audit passes (every table tenant-leading, indexes present). |
| **M5** | Supabase sync (phase 2, out of MVP) | Idempotent replay: same scan uploaded twice ⇒ one row (`ON CONFLICT DO NOTHING`); negative cross-tenant RLS tests; outbox drained offline→online. |

## 9. Verification Strategy

- **Golden-image harness** (`tools/omr_cli` + `omr_detect/testdata/golden/`): `spec → PDF render → rasterize at known DPI → synthetically mark bubbles (deterministic RNG: full/partial/faint/double/stray/erasure classes) → apply perturbations (perspective ≤30°, shadow gradient, AWB shift, JPEG q85, slight curl) → run pipeline → assert per-bubble vs injected truth`. Regenerates whenever a spec or threshold changes; runs in CI on host.
- **Per-stage error attribution**: every stage appends to a `StageTrace`; the harness reports error counts bucketed by stage (registration / warp / residual / threshold / classification) — this is what tells us when a CNN bubble classifier (LiteRT/ONNX, invoked only on PROBABLE bubbles) pays for itself.
- **Real-photo accuracy harness**: printed sheets filled by humans under pilot conditions (lamination glare, ceiling shadow bands, crumpled corners, faint pencil, pen bleed); ground-truth CSV; target ≥99% post-review with review-rate ≤2% (RescueOMR benchmark).
- **Printed-sheet calibration workflow** (in-app screen + SOP): print the calibration sheet (reference bubbles at known fill levels + fiducials + timing track) → capture → app reports per-region confidence margins and fiducial scores → pass if all margins exceed threshold, else warn on printer/paper/photocopy generation and suggest a threshold preset. Run when onboarding any institute/printer/paper stock; threshold config is scoped per layout version.
- **Device matrix**: one 2–4GB low-end Android (Redmi/A-series class) for frame-time + memory; one mid (Pixel a-series) as reference; one flagship; Android 11 specifically for share-sheet regression; iOS simulator reserved for the port.

## 10. Top 10 Risks & Mitigations

| # | Risk | Mitigation | Handled in |
|---|---|---|---|
| 1 | ~90% mobile-photo accuracy ceiling → visibly wrong marks | Confidence-scored human review queue as a mandatory product surface (PROBABLE band, unmarked-row floor, multi-mark flags) → ~99%+ | §3, §6-7, M2 |
| 2 | opencv_dart single-maintainer / module-trim / API churn | Pin 2.2.2 exactly; all `cv.*` behind `OpencvService`; calib3d enabled before pipeline code; arm64 smoke test in week 1 as go/no-go | §1, M0 gate |
| 3 | Per-frame OpenCV through the Dart bridge too slow on low-end devices | Live loop reads only ~640×480 quad + gates; bubbles always from the still; `EdgeAnalyzer` interface ready for Kotlin channel swap with decision criteria fixed at M0/M2 | §3, M0/M2 |
| 4 | Template-vs-print drift (classic silent killer) | One declarative mm spec compiles to BOTH PDF and detection template; `specHash` stored + verified; layouts immutable + versioned; QR encodes layoutId+version | §2, M0–M1 |
| 5 | Wrong answer key discovered after publishing | Immutable versioned keys + raw `bubble_reads` retained ⇒ re-grade is an insert, not a rescan; NTA key-correction states first-class | §4, §5, M2 |
| 6 | Global threshold fails under phone lighting / photocopies | Two-tier largest-gap thresholding (global looseness-4 + per-strip; MIN_JUMP 25/+5, MIN_GAP 30), strip-std outlier gate; CLAHE never in the measurement path | §3 stages 6–7 |
| 7 | Curl/curved sheets silently misread by corner-only homography | Timing track printed on the sheet + curvature residual gate → route to review/manual-crop rather than mis-grade; learned dewarping deferred | §3 stage 4, fallback ladder |
| 8 | Roll-number/set-code misread plausibly mis-attributes a student | Roll checksum digit + roster validation + exactly-one-per-digit-column rule + mandatory human confirmation on anomaly; set-code blank/multi/no-key flags | §3 stage 9, §6-7 |
| 9 | DPDP 2023 child-data exposure + image storage blowout | Roll numbers (not names) as primary student key; store warped grayscale + annotated thumbnail, drop 12MP originals after a grace window; retention job + audit log; institute = Data Fiduciary, app = Data Processor | §4, M4 |
| 10 | Play 16KB page-size rejection (hard deadline for API 35+) | `zipalign -c -P 16` on every bundled `.so` as an M0 gate and pre-release CI step; no ML Kit/GMS-only dependencies in the capture path | M0, §3 |

Also baked into the structure: multi-correct questions must **not** be rejected as "double marks" — `MULTI_CORRECT` with partial credit is schema- and strategy-supported from day one even though MVP ships SINGLE_CORRECT + INTEGER presets; and license hygiene — only OMRChecker (MIT) / LazyOMR (MIT) are borrowed as algorithm references, never OpenMCR (GPL + CC-NC art) or AndroidOMRHelper (no license).

## Critical files (first to be created)

- `packages/omr_spec/lib/src/models/sheet_spec.dart` — single source of truth both compilers derive from
- `packages/omr_spec/lib/src/compile/detection_template.dart` — spec → canvas-px geometry (twin: `pdf_sheet_compiler.dart`)
- `packages/omr_detect/lib/src/pipeline/pipeline.dart` — stage orchestration, fallback ladder, confidence aggregation
- `packages/omr_detect/lib/src/cv/opencv_service.dart` — the OpenCV firewall/seam
- `packages/omr_data/lib/src/app_db.dart` — drift schema, tenant-leading tables, PRAGMAs, migrations
- `packages/omr_core/lib/src/grading/scoring_strategy.dart` — strategy pattern + partial-credit set function + key-correction overrides

## End-to-end verification (how we'll know it works)

1. **M0**: print Preset A from the app → smoke test passes on a real device → `zipalign -c -P 16` green.
2. **M1**: `dart run tools/omr_cli golden --preset A --perturb all` reports 100% clean / ≥98% perturbed, with per-stage attribution.
3. **M2**: physical sheet, filled by hand with clean + adversarial marks → scan → instant score; bad sheets land in review; a corrected key re-grades the whole exam without rescanning (integration test).
4. **M3**: 200-student synthetic exam → all four report types generated <30s, CSV opens with Indian-script names intact, PDF/Excel share to WhatsApp on an Android 11 device.
5. **M4**: pilot institute prints sheets on their own printer → calibration passes → ≥150 real photos ≥99% accuracy post-review.
