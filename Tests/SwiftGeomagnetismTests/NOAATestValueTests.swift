import Foundation
import Numerics
import SwiftGeomagnetism
import SwiftGeomagnetismHiRes
import Testing

/**
 Validates against the test values NOAA's National Centers for Environmental Information publish
 with each model, computed by NOAA's reference C implementation in double precision. The files are
 included verbatim:

 - `WMM2025_TEST_VALUES.txt`: <https://www.ncei.noaa.gov/products/world-magnetic-model>, with grid
   variation.
 - `WMM2025COF_TestValues.txt`: the `WMM2025_TestValues.txt` file of NOAA's `WMM2025COF.zip`, 100
   points at higher precision.
 - `WMMHR2025_TEST_VALUES.txt`: from NOAA's `WMMHR2025COF.zip`.

 Each value must agree to within half a unit in its last printed decimal place. The 100-point file
 prints intensities and their rates to a millionth of a nanotesla, finer than its generator agrees
 with NOAA's reference C algorithm: its X column differs from that algorithm by up to 0.0008 nT.
 Those columns are therefore compared to within 0.001 nT (or nT/yr).
 */
@Suite
struct `NOAA test values` {
  private static let coefficientFileNanoteslaTolerance = 0.001

  @Test(arguments: try NOAATestValues.load("WMM2025_TEST_VALUES"))
  func `WMM2025 matches NOAA's published test values`(_ expected: NOAATestValue) throws {
    try expectAgreement(of: .wmm2025, with: expected)
  }

  @Test(arguments: try NOAATestValues.load("WMM2025COF_TestValues"))
  func `WMM2025 matches the test values distributed with its coefficient file`(
    _ expected: NOAATestValue
  ) throws {
    try expectAgreement(
      of: .wmm2025,
      with: expected,
      nanoteslaTolerance: Self.coefficientFileNanoteslaTolerance
    )
  }

  @Test(arguments: try NOAATestValues.load("WMMHR2025_TEST_VALUES"))
  func `WMMHR2025 matches NOAA's published test values`(_ expected: NOAATestValue) throws {
    try expectAgreement(of: .wmmHiRes2025, with: expected)
  }

  private func expectAgreement(
    of model: MagneticModel,
    with expected: NOAATestValue,
    nanoteslaTolerance: Double = 0
  ) throws {
    let field = try model.field(
      latitude: expected.latitude,
      longitude: expected.longitude,
      heightAboveEllipsoid: expected.heightMeters,
      decimalYear: expected.decimalYear
    )

    for (quantity, published) in expected.values where !quantity.isInput {
      let actual = quantity.value(in: field)
      guard let expectedValue = published.definedValue else {
        #expect(actual == nil, "\(quantity) should be undefined")
        continue
      }
      let actualValue = try #require(actual, "\(quantity) should be defined"),
        tolerance = max(
          published.roundingTolerance,
          quantity.isInNanoteslas ? nanoteslaTolerance : 0
        )
      #expect(
        quantity.error(of: actualValue, from: expectedValue) <= tolerance,
        "\(quantity): expected \(expectedValue), got \(actualValue)"
      )
    }
  }
}
