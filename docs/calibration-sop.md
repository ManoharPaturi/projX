# Printer calibration SOP (M4, plan §9)

The printed calibration sheet references this document. Run the procedure when
onboarding an institute/printer/paper stock, and again after any photocopy
generation — photocopies compress exactly the gray separation the reader
depends on.

## Why

Bubble reading is a separation problem: EMPTY bubbles print near the paper's
white (~230+ gray), FILLED ones near the ink's black (~60). The threshold
engine splits the two populations per strip (largest-gap, MIN_JUMP 25 /
confident 30). Whether those populations *separate on THIS printer, paper,
and phone* is a physical fact — this SOP measures it before an exam trusts
it.

## The sheet

`Calibration → Print calibration sheet` prints the reference sheet: the
SAME frame as Standard-90 (identical fiducials, timing track, QR zone, roll
grid, bubble style), with the exam columns replaced by reference bubbles at
known ink levels — full (near-black), faint (light pencil), mid
(half-pressure), empty — in three bands down the page (top/middle/bottom),
so a printer that fades toward one edge cannot average its way to a pass.

## Procedure

1. **Print at 100% scale** — "Actual size", NOT "fit to page" or
   "shrink oversized pages". A 4% fit-to-page shrink moves every bubble the
   reader measures. Fresh paper, single-sided.
2. **Photograph the sheet** from `Calibration → Photograph & analyze`:
   flat on a desk, whole sheet in frame, even lighting, no shadow bands or
   glare across the bubbles. The capture path is the production one — same
   decode, same fiducials, same warp, same bubble ROIs.
3. **Read the verdict** — judged on the WORST band, never an average:
   - **PASS** — minimum band margin ≥ 30 gray levels (the confident-jump
     bar). Ship with the Normal preset.
   - **TIGHT** — margin 25–29: usable, but one photocopy generation from
     misreads. Tap *Apply the 'strict' preset* and re-test after any
     photocopying.
   - **FAIL** — margin < 25, or registration failed (retake the photo:
     flat, evenly lit, whole sheet in frame before concluding the printer
     is at fault). Re-print at 100% on fresh paper; if it still fails,
     reject this printer/paper stock.
4. **For photocopies**: calibrate the *copy*, not the original — the copy
   generation is what students will actually fill.

## What the report shows per band

- **separation** — worst-case distance between the EMPTY and FILLED
  populations (brightest empty's floor vs the full row's darkest). This is
  the number the verdict is judged on.
- **split at** — where largest-gap thresholding would land between the
  populations.
- **faint at** — where the printer rendered the pencil-faint reference. If
  this sits close to the split, faint real-world pencil marks will land in
  the PROBABLE band and route to review (by design — review is the accuracy
  backstop, not a failure).

## Notes

- Threshold strictness (Strict/Normal/Relaxed, in Settings) shifts the
  capture quality gates — the blur floor especially. It is a capture-side
  knob, not a marking-side one; it never changes what counts as marked.
- The fills are ink, not geometry: they are not part of the spec JSON, do
  not enter `specHash`, and never bump `layoutVersion`.
