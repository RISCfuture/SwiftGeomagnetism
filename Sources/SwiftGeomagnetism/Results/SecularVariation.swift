/**
 The annual rate of change of a ``MagneticField``, from the model's secular-variation coefficients.

 Each property is the time derivative of the like-named property of ``MagneticField``: intensities
 in nanoteslas per year and angles in degrees per year.
 */
public struct SecularVariation: Sendable, Hashable, Codable {

  /// The rate of change of the northward component, in nanoteslas per year.
  public let northIntensity: Double

  /// The rate of change of the eastward component, in nanoteslas per year.
  public let eastIntensity: Double

  /// The rate of change of the downward component, in nanoteslas per year.
  public let downwardIntensity: Double

  /// The rate of change of the horizontal intensity, in nanoteslas per year.
  public let horizontalIntensity: Double

  /// The rate of change of the total intensity, in nanoteslas per year.
  public let totalIntensity: Double

  /// The rate of change of the declination, in degrees per year, east positive.
  public let declination: Double

  /// The rate of change of the inclination, in degrees per year, downward positive.
  public let inclination: Double

  /**
   Derives the rates of the horizontal intensity, total intensity, declination, and inclination
   from the rates of the three components.

   - Parameters:
     - field: The main field, in nanoteslas.
     - rates: The secular variation of `field`, in nanoteslas per year.
   */
  init(field: FieldVector, rates: FieldVector) {
    let horizontalSquared = field.north * field.north + field.east * field.east,
      horizontal = horizontalSquared.squareRoot(),
      totalSquared = horizontalSquared + field.down * field.down,
      horizontalRate = (field.north * rates.north + field.east * rates.east) / horizontal

    northIntensity = rates.north
    eastIntensity = rates.east
    downwardIntensity = rates.down
    horizontalIntensity = horizontalRate
    totalIntensity =
      (field.north * rates.north + field.east * rates.east + field.down * rates.down)
      / totalSquared.squareRoot()
    declination =
      (field.north * rates.east - field.east * rates.north) / horizontalSquared
      * AngleConversion.degreesPerRadian
    inclination =
      (horizontal * rates.down - field.down * horizontalRate) / totalSquared
      * AngleConversion.degreesPerRadian
  }
}
