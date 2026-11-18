import Foundation
import Numerics
import SwiftGeomagnetism
import Testing

@Suite
struct `Measurement extensions` {

  @Test
  func `converts between units of magnetic flux density`() {
    let gauss = Measurement(value: 0.5, unit: UnitMagneticFluxDensity.gauss)
    #expect(
      gauss.converted(to: .nanoteslas).value.isApproximatelyEqual(
        to: 50_000,
        relativeTolerance: 1e-12
      )
    )
    #expect(
      gauss.converted(to: .microteslas).value.isApproximatelyEqual(to: 50, relativeTolerance: 1e-12)
    )
    #expect(
      gauss.converted(to: .milligauss).value.isApproximatelyEqual(to: 500, relativeTolerance: 1e-12)
    )
    #expect(
      gauss.converted(to: .gammas).value.isApproximatelyEqual(to: 50_000, relativeTolerance: 1e-12)
    )
    #expect(
      gauss.converted(to: .teslas).value.isApproximatelyEqual(to: 5e-5, relativeTolerance: 1e-12)
    )
  }

  @Test
  func `accepts measurements in any unit`() throws {
    let date = try Date("2026-06-01T00:00:00Z", strategy: .iso8601)
    let expected = try MagneticModel.wmm2025.field(
      latitude: 45,
      longitude: -120,
      heightAboveEllipsoid: 3048,
      date: date
    )
    let measured = try MagneticModel.wmm2025.field(
      latitude: Measurement(value: .pi / 4, unit: .radians),
      longitude: Measurement(value: -120, unit: .degrees),
      heightAboveEllipsoid: Measurement(value: 10_000, unit: .feet),
      date: date
    )
    #expect(
      measured.northIntensity.isApproximatelyEqual(
        to: expected.northIntensity,
        relativeTolerance: 1e-12
      )
    )
    #expect(
      measured.declinationAngle.converted(to: .degrees).value.isApproximatelyEqual(
        to: expected.declination
      )
    )
    #expect(
      measured.totalFluxDensity.converted(to: .microteslas).value.isApproximatelyEqual(
        to: expected.totalIntensity / 1000,
        relativeTolerance: 1e-12
      )
    )
  }
}
