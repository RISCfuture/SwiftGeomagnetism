/**
 Generates Schmidt semi-normalized associated Legendre functions Pₙᵐ(cos θ) and their colatitude
 derivatives one degree at a time.

 For orders m ≥ 1 the functions are carried as Pₙᵐ / sin θ. Every such Pₙᵐ contains a factor of
 sin θ, so the quotient is finite at the geographic poles. It is also exactly the quantity the east
 component of the field needs, so the poles need no special-case summation. Neither recurrence
 divides by sin θ, and both stay numerically stable through degree 133.
 */
struct LegendreRecurrence: Sendable, Equatable {
  let maximumDegree: Int

  /// √((2n − 1) / 2n), indexed by degree n, for the diagonal step Pₙ₋₁ⁿ⁻¹ → Pₙⁿ.
  private let diagonalFactors: [Double]

  /// (2n − 1) / √(n² − m²), indexed triangularly, weighting the degree n − 1 term of the vertical step.
  private let previousDegreeFactors: [Double]

  /// √((n − 1)² − m²) / √(n² − m²), indexed triangularly, weighting the degree n − 2 term of the
  /// vertical step.
  private let secondPreviousDegreeFactors: [Double]

  init(maximumDegree: Int) {
    self.maximumDegree = maximumDegree
    let count = SphericalHarmonicCoefficients.count(maximumDegree: maximumDegree)
    var diagonalFactors = [Double](repeating: 0, count: maximumDegree + 1),
      previousDegreeFactors = [Double](repeating: 0, count: count),
      secondPreviousDegreeFactors = [Double](repeating: 0, count: count)

    for n in stride(from: 1, through: maximumDegree, by: 1) {
      diagonalFactors[n] = n == 1 ? 1 : (Double(2 * n - 1) / Double(2 * n)).squareRoot()
      for m in 0..<n {
        let index = SphericalHarmonicCoefficients.index(degree: n, order: m),
          divisor = Double(n * n - m * m).squareRoot()
        previousDegreeFactors[index] = Double(2 * n - 1) / divisor
        secondPreviousDegreeFactors[index] =
          Double((n - 1) * (n - 1) - m * m).squareRoot() / divisor
      }
    }

    self.diagonalFactors = diagonalFactors
    self.previousDegreeFactors = previousDegreeFactors
    self.secondPreviousDegreeFactors = secondPreviousDegreeFactors
  }

  /**
   Computes degree `n` from degrees `n − 1` and `n − 2`.

   - Parameters:
     - n: The degree to compute, at least 1.
     - cosθ: Cosine of the geocentric colatitude.
     - sinθ: Sine of the geocentric colatitude.
     - previous: Degree `n − 1`.
     - secondPrevious: Degree `n − 2`; ignored where its order exceeds its degree.
     - row: Receives degree `n` for orders 0 through `n`.
   */
  func computeDegree(
    _ n: Int,
    cosθ: Double,
    sinθ: Double,
    previous: LegendreRow,
    secondPrevious: LegendreRow,
    into row: inout LegendreRow
  ) {
    for m in 0..<n {
      let index = SphericalHarmonicCoefficients.index(degree: n, order: m),
        α = previousDegreeFactors[index],  // weight of the degree n − 1 term
        β = secondPreviousDegreeFactors[index],  // weight of the degree n − 2 term
        hasSecondPrevious = m <= n - 2,
        P̃ₙ₋₂ = hasSecondPrevious ? secondPrevious.reduced[m] : 0,  // reduced Pₙ₋₂ᵐ
        dPₙ₋₂ = hasSecondPrevious ? secondPrevious.derivative[m] : 0,  // dPₙ₋₂ᵐ/dθ
        Pₙ₋₁ = previous.unreduced(order: m, sinθ: sinθ)  // Pₙ₋₁ᵐ

      row.reduced[m] = α * cosθ * previous.reduced[m] - β * P̃ₙ₋₂
      row.derivative[m] = α * (cosθ * previous.derivative[m] - sinθ * Pₙ₋₁) - β * dPₙ₋₂
    }

    let γ = diagonalFactors[n]  // weight of the diagonal step from Pₙ₋₁ⁿ⁻¹
    if n == 1 {
      row.reduced[1] = 1
      row.derivative[1] = cosθ
    } else {
      let Pₙ₋₁ = previous.unreduced(order: n - 1, sinθ: sinθ)  // Pₙ₋₁ⁿ⁻¹
      row.reduced[n] = γ * sinθ * previous.reduced[n - 1]
      row.derivative[n] = γ * (cosθ * Pₙ₋₁ + sinθ * previous.derivative[n - 1])
    }
  }
}

/// One degree of Legendre function values, indexed by order.
struct LegendreRow {
  /// Pₙ⁰ at order 0, and Pₙᵐ / sin θ at orders m ≥ 1.
  var reduced: [Double]

  /// dPₙᵐ/dθ, the derivative with respect to geocentric colatitude.
  var derivative: [Double]

  /// The row for degree 0, sized to hold any degree through `maximumDegree`.
  static func degreeZero(maximumDegree: Int) -> Self {
    var row = Self(
      reduced: .init(repeating: 0, count: maximumDegree + 1),
      derivative: .init(repeating: 0, count: maximumDegree + 1)
    )
    row.reduced[0] = 1
    return row
  }

  /// Pₙᵐ itself, restoring the factor of sin θ removed at orders m ≥ 1.
  func unreduced(order m: Int, sinθ: Double) -> Double {
    m == 0 ? reduced[0] : sinθ * reduced[m]
  }
}
