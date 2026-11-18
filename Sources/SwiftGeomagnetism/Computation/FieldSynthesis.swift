internal import Foundation

/// A field vector resolved into north, east, and downward components.
struct FieldVector: Equatable {
  var north = 0.0
  var east = 0.0
  var down = 0.0

  /**
   Rotates the vector about the east axis from the geocentric frame into the geodetic frame.

   - Parameter ψ: Geocentric latitude minus geodetic latitude, in radians.
   */
  func rotatedToGeodetic(by ψ: Double) -> Self {
    let sinψ = sin(ψ), cosψ = cos(ψ)  // sine and cosine of the frame rotation angle
    return Self(
      north: north * cosψ - down * sinψ,
      east: east,
      down: north * sinψ + down * cosψ
    )
  }
}

/// The main field and its secular variation, both summed in a single pass of the expansion.
struct SynthesizedField {
  let field: FieldVector
  let secularVariation: FieldVector
}

/// Evaluates the spherical-harmonic expansion of a geomagnetic model.
struct FieldSynthesis {
  let coefficients: SphericalHarmonicCoefficients
  let recurrence: LegendreRecurrence

  private var maximumDegree: Int { coefficients.maximumDegree }

  /**
   Sums the field and its secular variation at a point, in the geocentric frame.

   - Parameters:
     - point: Where to evaluate the field.
     - yearsSinceEpoch: The decimal year minus the model epoch.
   */
  func evaluate(at point: SphericalCoordinate, yearsSinceEpoch: Double) -> SynthesizedField {
    let θ = Double.pi / 2 - point.φʹ  // geocentric colatitude (radians)
    let cosθ = cos(θ), sinθ = sin(θ)  // cosine and sine of the geocentric colatitude
    let (cosmλ, sinmλ) = longitudeHarmonics(point.λ)  // cos(mλ) and sin(mλ), indexed by order m
    let radiusRatio = GeomagneticReferenceSphere.radius / point.r

    var field = FieldVector(), secularVariation = FieldVector()
    var secondPrevious = LegendreRow.degreeZero(maximumDegree: maximumDegree),
      previous = secondPrevious,
      current = secondPrevious
    var radialFactor = radiusRatio * radiusRatio  // (a/r)ⁿ⁺², advanced as n increases

    for n in stride(from: 1, through: maximumDegree, by: 1) {
      radialFactor *= radiusRatio
      recurrence.computeDegree(
        n,
        cosθ: cosθ,
        sinθ: sinθ,
        previous: previous,
        secondPrevious: secondPrevious,
        into: &current
      )

      for m in 0...n {
        let index = SphericalHarmonicCoefficients.index(degree: n, order: m),
          P̃ = current.reduced[m],  // Pₙᵐ / sin θ for m ≥ 1, Pₙ⁰ for m = 0
          Pₙᵐ = current.unreduced(order: m, sinθ: sinθ),  // Schmidt semi-normalized Pₙᵐ(cos θ)
          dPₙᵐ = current.derivative[m],  // dPₙᵐ/dθ
          gₜ = coefficients.g(index, after: yearsSinceEpoch),  // gₙᵐ at the requested time (nT)
          hₜ = coefficients.h(index, after: yearsSinceEpoch)  // hₙᵐ at the requested time (nT)

        accumulate(
          into: &field,
          g: gₜ,
          h: hₜ,
          cosmλ: cosmλ[m],
          sinmλ: sinmλ[m],
          terms: .init(n: n, m: m, radialFactor: radialFactor, P̃: P̃, Pₙᵐ: Pₙᵐ, dPₙᵐ: dPₙᵐ)
        )
        accumulate(
          into: &secularVariation,
          g: coefficients.ġ[index],
          h: coefficients.ḣ[index],
          cosmλ: cosmλ[m],
          sinmλ: sinmλ[m],
          terms: .init(n: n, m: m, radialFactor: radialFactor, P̃: P̃, Pₙᵐ: Pₙᵐ, dPₙᵐ: dPₙᵐ)
        )
      }

      swap(&secondPrevious, &previous)
      swap(&previous, &current)
    }

    return SynthesizedField(field: field, secularVariation: secularVariation)
  }

  /// cos(mλ) and sin(mλ) for every order, by the angle-addition recurrence.
  private func longitudeHarmonics(_ λ: Double) -> (cos: [Double], sin: [Double]) {
    let cosλ = cos(λ), sinλ = sin(λ)  // cosine and sine of the longitude
    var cosmλ = [Double](repeating: 1, count: maximumDegree + 1),  // cos(mλ), indexed by order m
      sinmλ = [Double](repeating: 0, count: maximumDegree + 1)  // sin(mλ), indexed by order m

    for m in stride(from: 1, through: maximumDegree, by: 1) {
      cosmλ[m] = cosmλ[m - 1] * cosλ - sinmλ[m - 1] * sinλ
      sinmλ[m] = sinmλ[m - 1] * cosλ + cosmλ[m - 1] * sinλ
    }
    return (cosmλ, sinmλ)
  }

  /// Adds one (n, m) term of the expansion, for coefficients `g` and `h`, to `vector`; `cosmλ` and
  /// `sinmλ` are the cosine and sine of the order times the longitude.
  private func accumulate(
    into vector: inout FieldVector,
    g: Double,
    h: Double,
    cosmλ: Double,
    sinmλ: Double,
    terms: HarmonicTerms
  ) {
    let inPhase = g * cosmλ + h * sinmλ, quadrature = g * sinmλ - h * cosmλ
    vector.north += terms.radialFactor * inPhase * terms.dPₙᵐ
    vector.east += terms.radialFactor * Double(terms.m) * quadrature * terms.P̃
    vector.down -= terms.radialFactor * Double(terms.n + 1) * inPhase * terms.Pₙᵐ
  }
}

/// The coefficient-independent factors of one (n, m) term.
private struct HarmonicTerms {
  let n: Int  // degree
  let m: Int  // order
  let radialFactor: Double  // (a/r)ⁿ⁺², where a is the reference radius and r the geocentric radius
  let P̃: Double  // Pₙᵐ / sin θ for m ≥ 1, Pₙ⁰ for m = 0
  let Pₙᵐ: Double  // Schmidt semi-normalized associated Legendre function of cos θ
  let dPₙᵐ: Double  // derivative of Pₙᵐ with respect to colatitude θ
}
