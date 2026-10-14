# Optimization plan (post-1.0)

Goal: a teacher scanning a class of 40–60 sheets on a budget Android phone
should never see the app freeze, and each sheet should take about a second.
Work happens in phases, one PR each. Each phase must show measured numbers
before and after, on the same phone.

## Phase O1 — Measure first

- Add timing around each scan step: capture, decode, pipeline stages
  (registration, sampling, thresholds, decode) and DB intake and grading.
  Send the timings to `debugPrint` in profile builds only.
- Run `flutter run --profile` on a low-end arm64 phone (2–3 GB RAM). Record
  the time per sheet, dropped UI frames and peak memory for 20 sheets in a row.
- Add a `tools/omr_cli` benchmark that runs the pipeline over the fixture
  images, so CI can catch slowdowns without a phone.
- Write the baseline numbers into this file.

### Baseline (O1, 2026-10-14)

`omr_cli bench --runs 3`, Standard-90, noise ±6, Apple-silicon Mac (JIT).
Phones will be several times slower; compare runs on one machine only.

| Photo | MP | decode | pipeline | of which registration | accuracy |
|---|---|---|---|---|---|
| 1080×1440 | 1.6 | 4 ms | 796 ms | ~790 ms | 100% |
| 1200×1600 | 1.9 | 5 ms | 1024 ms | ~1015 ms | 100% |
| 1536×2048 | 3.1 | 8 ms | 1749 ms | ~1735 ms | 100% |
| 2250×3000 | 6.8 | 17 ms | 4019 ms | ~3990 ms | 100% |
| 3000×4000 | 12.0 | 30 ms | 7419 ms | ~7400 ms | 100% |

Finding: **fiducial registration is >98 % of the time** and grows with
pixel count (10 template scales × 2 peak searches × 4 quadrants at full
resolution). Threshold, read and curvature together take under 5 ms.
Decode is cheap. So O3 should search for anchors on a downscaled copy and
refine at full resolution, rather than only lowering the camera
resolution.

On a phone, every scan logs a line like
`[scan-timing] total=… capture=… evaluate=… persist=… grade=… | registration=…`
in debug and profile builds.

## Phase O2 — Keep the screen responsive while scanning (biggest win)

Today `OmrStillEvaluator.evaluate` decodes the photo and runs `OmrPipeline`
on the **UI isolate** (`app/lib/features/capture/still_evaluator.dart`).
The spinner freezes for the whole time detection takes.

- Run decode and pipeline in `Isolate.run`, passing only the bytes, the
  template and the threshold config. Check first that dartcv4 handles and
  the template can cross isolates; otherwise rebuild them inside the
  isolate.
- Optionally keep one long-lived worker isolate, so OpenCV start-up cost is
  paid once per session rather than once per sheet.
- Acceptance: no frame over 32 ms on the capture screen during a scan.

**Done (O2):** `OmrStillEvaluator` decodes and reads on `Isolate.run` (the
DB reads stay on drift's isolate). The live preview loop runs in a
long-lived `LiveAnalyzerWorker` isolate that owns the per-session blur
history and dwell. The scanner keeps one frame in flight and drops the
rest. The camera source caps analysis at ~15 fps before it copies the Y
plane. The UI isolate now only draws.

## Phase O3 — Smaller images, less work per sheet

- The camera uses `ResolutionPreset.max` (12–50 MP on modern phones). The
  sheet only needs enough pixels per bubble. Measure the accuracy against
  resolution curve on the fixture set, then cap at the lowest preset that
  keeps 100% fixture accuracy (likely `veryHigh`/1080p or `ultraHigh`).
- Decode straight to grayscale at the target size. Do not build a full RGB
  buffer first.
- Reuse `Mat` buffers between sheets and dispose them deterministically,
  so the garbage collector doesn't stall and memory doesn't creep up over
  a 60-sheet session.

**Done (O3):**
- **Coarse-to-fine registration.** The anchor sweep runs on a copy
  downscaled to 640 px wide. Each accepted anchor is then re-centred at
  full resolution with one small single-scale match. Accept/reject
  decisions and scores are unchanged.
- **Score maps reused.** Each (shape, scale) score map is computed once and
  queried twice (best peak, then the separated second peak), where the
  sweep used to run twice.
- **No copies before matching.** The quadrant is matched through an ROI
  header instead of a copied crop.
- **Decoding:** `OmrPipeline.evaluateStill` decodes straight into a mat
  (no host copies). A still at least twice 3000 px on its short side
  (48–108 MP sensors) is decoded at 1/2, 1/4 or 1/8 size by the codec.
- **Camera resolution stays at `max`.** The layouts' capture floor is
  11.4 px/mm (Standard-90) and 13.3 px/mm (NEET-180) on paper. That is
  ~2400–2800 px across the sheet, which the 1080p/4K presets cannot
  guarantee. Oversized stills are handled at decode instead.

| Photo | before (O1) | after (O3) | accuracy |
|---|---|---|---|
| 1080×1440 | 800 ms | 159 ms | 100% |
| 3000×4000 (12 MP) | 7452 ms | 191 ms | 100% (both presets) |

Time per sheet no longer grows with camera resolution (Mac, JIT; same
bench).

## Phase O4 — Database and grading at class scale

- `gradeScan` / `gradeExam` reload the key, the template and the roster
  on every call. Cache them per exam and drop the cache when the key or
  the roster changes.
- Wrap per-sheet intake writes (scan, reads, review items, result) in one
  transaction.
- Check that the reviews, scans and results lookups by exam use indexes:
  run `EXPLAIN QUERY PLAN` on the hot queries and add indexes in a
  migration if they don't.
- After a scan, refresh only the affected widgets. At the moment
  `AppState.refresh()` rebuilds everything that listens to `AppState`.
- Seed 500 students and 2,000 scans, then time the dashboard, review queue,
  Results and Analysis screens.

## Phase O5 — App size and start-up

- The current arm64 debug APK is about 72 MB. Measure the release APK and
  AAB with `flutter build apk --analyze-size`.
- Enable R8 (`isMinifyEnabled`/`isShrinkResources`) with keep rules for the
  OpenCV and drift native code, and test on a device.
- Check what the dartcv4 native library includes. Keep only the OpenCV
  modules the pipeline uses (core, imgproc, imgcodecs) if the build hook
  allows it.
- Delay non-essential start-up work (fonts for PDFs, analytics) until it is
  first used. Target a cold start under 2 s on the reference phone.

## Phase O6 — Reports

- Build the class PDF and Excel files in an isolate. Large classes
  currently block the UI while generating.
- Load the Noto fonts once per session, not once per report.

## Order and effort

| Phase | Effort | Impact |
|---|---|---|
| O1 measure | S | needed to judge the rest |
| O2 isolate | M | removes the freeze while scanning |
| O3 image size | M | 2–5× faster per sheet, less memory |
| O4 DB/grading | M | keeps big classes fast |
| O5 size/start-up | M | smaller download, faster launch |
| O6 reports | S | no freeze when exporting |

O1 → O2 → O3 deliver most of the benefit. O4–O6 can follow in any order.
