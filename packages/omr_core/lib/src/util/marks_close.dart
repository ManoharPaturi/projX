library;

/// Marks can be fractional (partial credit, tuned penalties), so they are
/// carried as `double` — and doubles must never be compared with `==` in a
/// grading system. This is the one comparison to use, in tests and in any
/// consumer that diffs two results.
///
/// Tolerance defaults to `1e-9`, which is far below any mark a student could
/// notice and far above the drift from summing a few hundred doubles.
bool marksClose(num a, num b, [num tolerance = 1e-9]) =>
    (a - b).abs() <= tolerance;
