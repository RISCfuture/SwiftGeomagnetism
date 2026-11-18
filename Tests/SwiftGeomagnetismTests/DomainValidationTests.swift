import Foundation
import SwiftGeomagnetism
import Testing

@Suite
struct `Domain validation` {
  private static let model = MagneticModel.wmm2025

  private static let rejectedInputs:
    [(
      latitude: Double, longitude: Double, height: Double, decimalYear: Double,
      error: MagneticFieldError
    )] = [
      (90.000_001, 0, 0, 2026, .invalidLatitude(90.000_001)),
      (-91, 0, 0, 2026, .invalidLatitude(-91)),
      (0, .infinity, 0, 2026, .invalidLongitude(.infinity)),
      (0, 0, -1_000.1, 2026, .heightOutsideValidRange(-1_000.1)),
      (0, 0, 850_000.1, 2026, .heightOutsideValidRange(850_000.1)),
      (
        0, 0, 0, 2024.999,
        .dateOutsideValidityPeriod(decimalYear: 2024.999, validityPeriod: 2025..<2030)
      ),
      (0, 0, 0, 2030, .dateOutsideValidityPeriod(decimalYear: 2030, validityPeriod: 2025..<2030))
    ]

  private static let acceptedInputs:
    [(latitude: Double, longitude: Double, height: Double, decimalYear: Double)] = [
      (90, 0, 0, 2025),
      (-90, 0, 0, 2029.999_999),
      (0, 540, -1_000, 2026),
      (0, -720, 850_000, 2026)
    ]

  @Test(arguments: rejectedInputs)
  func `rejects inputs outside the model's domain`(
    _ latitude: Double,
    _ longitude: Double,
    _ height: Double,
    _ decimalYear: Double,
    _ expected: MagneticFieldError
  ) {
    #expect(throws: expected) {
      try Self.model.field(
        latitude: latitude,
        longitude: longitude,
        heightAboveEllipsoid: height,
        decimalYear: decimalYear
      )
    }
  }

  @Test(arguments: acceptedInputs)
  func `accepts inputs at the edges of the model's domain`(
    _ latitude: Double,
    _ longitude: Double,
    _ height: Double,
    _ decimalYear: Double
  ) throws {
    let field = try Self.model.field(
      latitude: latitude,
      longitude: longitude,
      heightAboveEllipsoid: height,
      decimalYear: decimalYear
    )
    #expect(field.totalIntensity.isFinite)
  }

  @Test
  func `treats longitudes a full turn apart as the same meridian`() throws {
    let field = try Self.model.field(latitude: 40, longitude: -105, decimalYear: 2026)
    let wrapped = try Self.model.field(latitude: 40, longitude: 255, decimalYear: 2026)
    #expect(abs(field.declination - wrapped.declination) < 1e-9)
  }

  @Test
  func `names years without digit grouping when a date is outside the validity period`() throws {
    let error = MagneticFieldError.dateOutsideValidityPeriod(
      decimalYear: 2031.25,
      validityPeriod: 2025..<2030
    )
    let reason = try #require(error.failureReason)
    #expect(reason.contains("2031"))
    #expect(reason.contains("2025"))
    #expect(reason.contains("2030"))
  }
}
