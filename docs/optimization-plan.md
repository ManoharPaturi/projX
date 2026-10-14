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
