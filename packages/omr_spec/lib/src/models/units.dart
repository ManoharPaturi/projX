/// Geometry primitives for the sheet spec. All values are millimetres.
///
/// Convention: the origin is the TOP-LEFT corner of the page, x grows right,
/// y grows DOWN. This matches author intuition; the PDF compiler converts to
/// the pdf package's bottom-left origin in exactly one place, and the
/// detection-template compiler scales straight to canvas pixels.
library;

/// An (x, y) point in mm.
extension type const MmPoint._((double, double) _v) {
  const MmPoint(double x, double y) : this._((x, y));

  double get x => _v.$1;
  double get y => _v.$2;

  MmPoint operator +(MmPoint o) => MmPoint(x + o.x, y + o.y);
  MmPoint operator -(MmPoint o) => MmPoint(x - o.x, y - o.y);
}

/// An axis-aligned rectangle in mm, defined by its top-left corner and size.
extension type const MmRect._((double, double, double, double) _v) {
  const MmRect(double x, double y, double w, double h)
      : this._((x, y, w, h));

  double get x => _v.$1;
  double get y => _v.$2;
  double get w => _v.$3;
  double get h => _v.$4;

  double get left => x;
  double get top => y;
  double get right => x + w;
  double get bottom => y + h;
  double get centerX => x + w / 2;
  double get centerY => y + h / 2;

  /// Grown symmetrically by [p] mm on every side (negative shrinks).
  MmRect inflate(double p) => MmRect(x - p, y - p, w + 2 * p, h + 2 * p);

  bool contains(MmRect o) =>
      o.left >= left && o.right <= right && o.top >= top && o.bottom <= bottom;

  bool intersects(MmRect o) =>
      !(o.right <= left || o.left >= right || o.bottom <= top || o.top >= bottom);
}
