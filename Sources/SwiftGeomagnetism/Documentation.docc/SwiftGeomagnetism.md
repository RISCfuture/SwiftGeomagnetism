# ``SwiftGeomagnetism``

@Metadata {
    @DisplayName("SwiftGeomagnetism")
}

Magnetic declination, inclination, and field intensity from the World Magnetic Model.

## Overview

SwiftGeomagnetism evaluates spherical-harmonic models of Earth's main magnetic field. It bundles
the current World Magnetic Model, WMM2025, which is valid from 2025.0 through 2029. It also reads
any coefficient (COF) file in NOAA's WMM format, so you can load a future model release or the
high-resolution WMMHR2025.

```swift
import SwiftGeomagnetism

let field = try MagneticModel.wmm2025.field(latitude: 37.62, longitude: -122.38)
print(field.declination)       // ≈ 12.8 (degrees east of true north)
print(field.inclination)       // ≈ 60.9 (degrees below horizontal)
print(field.totalIntensity)    // ≈ 47,280 (nanoteslas)
```

Every result includes its ``SecularVariation``: the annual rate of change of each quantity.
Validation runs against NOAA's published test values and against the British Geological
Survey's independent implementation. Results match NOAA's test values to their published
precision.

## Topics

### Essentials

- <doc:GettingStarted>
- ``MagneticModel``
- ``MagneticField``

### Results

- ``SecularVariation``
- ``UnitMagneticFluxDensity``

### Models and Accuracy

- <doc:CustomModels>
- <doc:Accuracy>

### Errors

- ``MagneticFieldError``
- ``COFParseError``
