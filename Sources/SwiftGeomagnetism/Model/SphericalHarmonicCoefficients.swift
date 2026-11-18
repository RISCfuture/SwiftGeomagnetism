/// Schmidt semi-normalized Gauss coefficients and their secular variation, stored in flat triangular
/// arrays indexed by ``index(degree:order:)``.
struct SphericalHarmonicCoefficients: Sendable, Equatable {
  let maximumDegree: Int
  let g: [Double]  // main-field Gauss coefficient gₙᵐ at the model epoch: cos(mλ) term (nT)
  let h: [Double]  // main-field Gauss coefficient hₙᵐ at the model epoch: sin(mλ) term (nT)
  let ġ: [Double]  // secular variation of gₙᵐ (nT/yr)
  let ḣ: [Double]  // secular variation of hₙᵐ (nT/yr)

  /// The number of (n, m) pairs for degrees 0 through `maximumDegree`.
  static func count(maximumDegree: Int) -> Int {
    index(degree: maximumDegree, order: maximumDegree) + 1
  }

  /// The position of the (n, m) term in a triangular array.
  static func index(degree n: Int, order m: Int) -> Int {
    n * (n + 1) / 2 + m
  }

  /// gₙᵐ at the term `index`, advanced from the epoch by its secular variation.
  func g(_ index: Int, after yearsSinceEpoch: Double) -> Double {
    g[index] + ġ[index] * yearsSinceEpoch
  }

  /// hₙᵐ at the term `index`, advanced from the epoch by its secular variation.
  func h(_ index: Int, after yearsSinceEpoch: Double) -> Double {
    h[index] + ḣ[index] * yearsSinceEpoch
  }
}
