import Foundation
import Numerics
import SwiftGeomagnetism
import SwiftGeomagnetismHiRes
import Testing

@Suite
struct `COF parsing` {
  private static let terminator = String(repeating: "9", count: 48)

  /// An axial dipole: g₁⁰ = −30,000 nT, changing by +10 nT/yr, and no other terms.
  private static let dipole = """
        2025.0            DIPOLE     01/02/2025
      1  0  -30000.0       0.0       10.0        0.0
      1  1       0.0       0.0        0.0        0.0
    \(terminator)
    """

  private static let malformedFiles: [(text: String, error: COFParseError)] = [
    ("2025.0 WMM-2025\n\(terminator)", .malformedHeader("2025.0 WMM-2025")),
    ("2025.0 WMM-2025 13/45/2024\n\(terminator)", .malformedHeader("2025.0 WMM-2025 13/45/2024")),
    (
      "2025.0 TEST 01/01/2025\n1 0 -29351.8 0.0 12.0\n\(terminator)",
      .malformedCoefficientLine(lineNumber: 2, line: "1 0 -29351.8 0.0 12.0")
    ),
    (
      "2025.0 TEST 01/01/2025\n1 2 1 1 0 0\n\(terminator)",
      .invalidDegreeOrOrder(lineNumber: 2, degree: 1, order: 2)
    ),
    (
      "2025.0 TEST 01/01/2025\n1 0 1 0 0 0\n1 1 1 1 0 0\n1 0 1 0 0 0\n\(terminator)",
      .duplicateCoefficient(lineNumber: 4, degree: 1, order: 0)
    ),
    (
      "2025.0 TEST 01/01/2025\n1 0 1 0 0 0\n2 0 1 0 0 0\n\(terminator)",
      .missingCoefficient(degree: 1, order: 1)
    ),
    ("2025.0 TEST 01/01/2025\n1 0 1 0 0 0\n1 1 1 1 0 0\n", .missingTerminator)
  ]

  /// (a/r)³ for a point on the WGS 84 ellipsoid at the equator or a pole.
  private static func radiusRatioCubed(atRadius radius: Double) -> Double {
    let ratio = 6371.2 / radius
    return ratio * ratio * ratio
  }

  @Test
  func `reads the bundled models' headers`() {
    #expect(MagneticModel.wmm2025.name == "WMM-2025")
    #expect(MagneticModel.wmm2025.epoch == 2025)
    #expect(MagneticModel.wmm2025.maximumDegree == 12)
    #expect(MagneticModel.wmm2025.validityPeriod == 2025..<2030)
    #expect(MagneticModel.wmm2025.releaseDate == Date(timeIntervalSince1970: 1_731_456_000))
    #expect(MagneticModel.wmmHiRes2025.name == "WMMHR-2025")
    #expect(MagneticModel.wmmHiRes2025.maximumDegree == 133)
  }

  @Test
  func `evaluates a custom model against the analytic dipole field`() throws {
    let model = try MagneticModel(parsing: Self.dipole)
    #expect(model.maximumDegree == 1)

    let gauss = -30_000.0 + 10 * 2  // g₁⁰ two years after the epoch
    let equator = try model.field(latitude: 0, longitude: 0, decimalYear: 2027)
    let equatorScale = Self.radiusRatioCubed(atRadius: 6378.137)
    #expect(
      equator.northIntensity.isApproximatelyEqual(
        to: -gauss * equatorScale,
        relativeTolerance: 1e-12
      )
    )
    #expect(equator.eastIntensity.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-9))
    #expect(equator.downwardIntensity.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-9))
    #expect(
      equator.secularVariation.northIntensity.isApproximatelyEqual(
        to: -10 * equatorScale,
        relativeTolerance: 1e-12
      )
    )

    let pole = try model.field(latitude: 90, longitude: 0, decimalYear: 2027)
    let poleScale = Self.radiusRatioCubed(atRadius: 6378.137 * (1 - 1 / 298.257223563))
    #expect(
      pole.downwardIntensity.isApproximatelyEqual(
        to: -2 * gauss * poleScale,
        relativeTolerance: 1e-12
      )
    )
    #expect(pole.horizontalIntensity.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-9))
  }

  @Test
  func `loads a coefficient file from a URL`() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).COF")
    try Self.dipole.write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }

    let model = try MagneticModel(contentsOf: url)
    #expect(model.name == "DIPOLE")
    #expect(model.releaseDate == Date(timeIntervalSince1970: 1_735_776_000))
  }

  @Test(arguments: malformedFiles)
  func `rejects a malformed coefficient file`(_ text: String, _ expected: COFParseError) {
    #expect(throws: expected) { try MagneticModel(parsing: text) }
  }
}
