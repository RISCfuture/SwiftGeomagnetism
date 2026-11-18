public import Foundation

/**
 Units of magnetic flux density (the B field), for expressing ``MagneticField`` intensities as
 `Measurement`s. The base unit is the tesla.
 */
public final class UnitMagneticFluxDensity: Dimension, @unchecked Sendable {
  private static let teslasPerMicrotesla = 1e-6,
    teslasPerNanotesla = 1e-9,
    teslasPerGauss = 1e-4,
    teslasPerMilligauss = 1e-7

  /// Teslas (T), the SI unit.
  public static let teslas = UnitMagneticFluxDensity(
    symbol: "T",
    converter: UnitConverterLinear(coefficient: 1)
  )

  /// Microteslas (µT).
  public static let microteslas = UnitMagneticFluxDensity(
    symbol: "µT",
    converter: UnitConverterLinear(coefficient: teslasPerMicrotesla)
  )

  /// Nanoteslas (nT), the unit the World Magnetic Model reports.
  public static let nanoteslas = UnitMagneticFluxDensity(
    symbol: "nT",
    converter: UnitConverterLinear(coefficient: teslasPerNanotesla)
  )

  /// Gammas (γ), the traditional geomagnetic unit, equal to one nanotesla.
  public static let gammas = UnitMagneticFluxDensity(
    symbol: "γ",
    converter: UnitConverterLinear(coefficient: teslasPerNanotesla)
  )

  /// Gauss (G), the CGS unit.
  public static let gauss = UnitMagneticFluxDensity(
    symbol: "G",
    converter: UnitConverterLinear(coefficient: teslasPerGauss)
  )

  /// Milligauss (mG).
  public static let milligauss = UnitMagneticFluxDensity(
    symbol: "mG",
    converter: UnitConverterLinear(coefficient: teslasPerMilligauss)
  )

  override public static func baseUnit() -> UnitMagneticFluxDensity { teslas }
}
