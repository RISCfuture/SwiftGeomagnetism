import Foundation
import SwiftGeomagnetism
import Testing

/**
 Validates against the British Geological Survey's World Magnetic Model web service
 (<https://geomag.bgs.ac.uk/web_service/GMModels>), an implementation independent of NOAA's. These
 points exercise what NOAA's test values don't: the geographic poles themselves, calendar dates
 instead of decimal years, and heights at the edges of the model's domain.

 Each value must agree to within half a unit in its last printed decimal place. Angles get a further
 0.0001° for the difference between the two implementations, which reaches 0.00004° beyond rounding
 in the declination at the South Pole.
 */
@Suite
struct `BGS reference values` {
  private static let angleImplementationAllowance = 0.0001

  @Test(arguments: try BGSReferenceValues.load())
  func `WMM2025 matches BGS's independent implementation`(_ expected: BGSReferenceValue) throws {
    let field = try MagneticModel.wmm2025.field(
      latitude: expected.latitude,
      longitude: expected.longitude,
      heightAboveEllipsoid: expected.heightMeters,
      date: expected.date
    )

    for (quantity, published) in expected.values {
      let actual = try #require(quantity.value(in: field), "\(quantity) should be defined"),
        allowance = quantity.isAngle ? Self.angleImplementationAllowance : 0
      #expect(
        quantity.error(of: actual, from: published.value) <= published.roundingTolerance
          + allowance,
        "\(quantity): expected \(published.value), got \(actual)"
      )
    }
  }
}
