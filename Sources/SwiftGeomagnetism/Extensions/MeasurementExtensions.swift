public import Foundation

// MARK: - MagneticModel

extension MagneticModel {
  /**
   Calculates the magnetic field at a point and instant, taking `Measurement` arguments.

   - Parameters:
     - latitude: Geodetic latitude on the WGS 84 ellipsoid, from −90° to 90°.
     - longitude: Longitude east. Any finite value is accepted.
     - heightAboveEllipsoid: Height above the WGS 84 ellipsoid, within ``validHeights``.
     - date: The instant, which must fall within ``validityPeriod``.
   - Returns: The predicted field and its secular variation.
   - Throws: ``MagneticFieldError`` if any argument is outside the model's domain.
   */
  public func field(
    latitude: Measurement<UnitAngle>,
    longitude: Measurement<UnitAngle>,
    heightAboveEllipsoid: Measurement<UnitLength> = .init(value: 0, unit: .meters),
    date: Date = .now
  ) throws(MagneticFieldError) -> MagneticField {
    try field(
      latitude: latitude.converted(to: .degrees).value,
      longitude: longitude.converted(to: .degrees).value,
      heightAboveEllipsoid: heightAboveEllipsoid.converted(to: .meters).value,
      date: date
    )
  }
}

// MARK: - MagneticField

extension MagneticField {
  /// The northward component X.
  public var northFluxDensity: Measurement<UnitMagneticFluxDensity> {
    .init(value: northIntensity, unit: .nanoteslas)
  }

  /// The eastward component Y.
  public var eastFluxDensity: Measurement<UnitMagneticFluxDensity> {
    .init(value: eastIntensity, unit: .nanoteslas)
  }

  /// The downward component Z.
  public var downwardFluxDensity: Measurement<UnitMagneticFluxDensity> {
    .init(value: downwardIntensity, unit: .nanoteslas)
  }

  /// The horizontal intensity H.
  public var horizontalFluxDensity: Measurement<UnitMagneticFluxDensity> {
    .init(value: horizontalIntensity, unit: .nanoteslas)
  }

  /// The total intensity F.
  public var totalFluxDensity: Measurement<UnitMagneticFluxDensity> {
    .init(value: totalIntensity, unit: .nanoteslas)
  }

  /// The declination D (magnetic variation), east positive.
  public var declinationAngle: Measurement<UnitAngle> {
    .init(value: declination, unit: .degrees)
  }

  /// The inclination I (dip), downward positive.
  public var inclinationAngle: Measurement<UnitAngle> {
    .init(value: inclination, unit: .degrees)
  }

  /// The grid variation (grivation) poleward of 55° latitude; `nil` elsewhere.
  public var gridVariationAngle: Measurement<UnitAngle>? {
    gridVariation.map { .init(value: $0, unit: .degrees) }
  }
}

// MARK: - SecularVariation

extension SecularVariation {
  /// The change in the northward component over one year.
  public var annualNorthFluxDensityChange: Measurement<UnitMagneticFluxDensity> {
    .init(value: northIntensity, unit: .nanoteslas)
  }

  /// The change in the eastward component over one year.
  public var annualEastFluxDensityChange: Measurement<UnitMagneticFluxDensity> {
    .init(value: eastIntensity, unit: .nanoteslas)
  }

  /// The change in the downward component over one year.
  public var annualDownwardFluxDensityChange: Measurement<UnitMagneticFluxDensity> {
    .init(value: downwardIntensity, unit: .nanoteslas)
  }

  /// The change in the horizontal intensity over one year.
  public var annualHorizontalFluxDensityChange: Measurement<UnitMagneticFluxDensity> {
    .init(value: horizontalIntensity, unit: .nanoteslas)
  }

  /// The change in the total intensity over one year.
  public var annualTotalFluxDensityChange: Measurement<UnitMagneticFluxDensity> {
    .init(value: totalIntensity, unit: .nanoteslas)
  }

  /// The change in the declination over one year.
  public var annualDeclinationChange: Measurement<UnitAngle> {
    .init(value: declination, unit: .degrees)
  }

  /// The change in the inclination over one year.
  public var annualInclinationChange: Measurement<UnitAngle> {
    .init(value: inclination, unit: .degrees)
  }
}
