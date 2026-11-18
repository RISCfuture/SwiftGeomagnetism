# SwiftGeomagnetism

[![CI](https://github.com/riscfuture/SwiftGeomagnetism/actions/workflows/ci.yml/badge.svg)](https://github.com/riscfuture/SwiftGeomagnetism/actions/workflows/ci.yml)
[![Documentation](https://github.com/riscfuture/SwiftGeomagnetism/actions/workflows/documentation.yml/badge.svg)](https://riscfuture.github.io/SwiftGeomagnetism/)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS%20|%20Linux-blue.svg)](https://swift.org)

Magnetic declination, inclination, and field intensity for Swift, from NOAA and the British
Geological Survey's World Magnetic Model.

## Features

- **Current model built in**: bundles WMM2025, the current World Magnetic Model, valid from
  2025.0 through 2029
- **Custom models**: loads any coefficient (COF) file in NOAA's WMM format, of any degree, so a
  future release works without a library update
- **High resolution on request**: the optional `SwiftGeomagnetismHiRes` library adds the
  degree-133 WMMHR2025. Apps that don't link it don't bundle its 530 KB of coefficients
- **Complete results**: X, Y, Z, H, F, declination, inclination, polar grid variation, and the
  secular variation of each
- **Exact at the poles**: Legendre recurrences that never divide by sin θ, so the poles need no
  special case
- **Fast**: about 0.6 µs per WMM2025 evaluation in a release build on Apple silicon
- **Validated**: tested against NOAA's published test values and the British Geological Survey's
  independent implementation
- **Foundation `Measurement`s**: angle, length, and magnetic flux density (`UnitMagneticFluxDensity`)
  for arguments and results
- **Swift 6 concurrency**: models and results are immutable and `Sendable`
- **Linux support**: no Apple-only dependencies outside the optional CoreLocation convenience

## Requirements

- Swift 6.2+
- macOS 13+, iOS 16+, tvOS 16+, watchOS 9+, visionOS 1+, or Linux

## Installation

Add SwiftGeomagnetism to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/riscfuture/SwiftGeomagnetism.git", from: "1.0.0")
]
```

Then add the library to your target, plus `SwiftGeomagnetismHiRes` if you want WMMHR2025:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftGeomagnetism", package: "SwiftGeomagnetism"),
        .product(name: "SwiftGeomagnetismHiRes", package: "SwiftGeomagnetism")  // optional
    ]
)
```

## Quick Start

```swift
import SwiftGeomagnetism

let field = try MagneticModel.wmm2025.field(
    latitude: 37.62,
    longitude: -122.38,
    heightAboveEllipsoid: 0,  // meters above the WGS 84 ellipsoid
    date: .now
)

print(field.declination)                  // ≈ 12.8 (degrees east of true north)
print(field.inclination)                  // ≈ 60.9 (degrees below horizontal)
print(field.totalIntensity)               // ≈ 47,280 (nanoteslas)
print(field.secularVariation.declination) // ≈ −0.09 (degrees per year)
```

### Measurements

```swift
let field = try MagneticModel.wmm2025.field(
    latitude: Measurement(value: 37.62, unit: .degrees),
    longitude: Measurement(value: -122.38, unit: .degrees),
    heightAboveEllipsoid: Measurement(value: 10_000, unit: .feet)
)
field.declinationAngle                              // Measurement<UnitAngle>
field.totalFluxDensity.converted(to: .microteslas)  // ≈ 47.3 µT
```

### Custom and High-Resolution Models

```swift
let custom = try MagneticModel(contentsOf: cofURL)

import SwiftGeomagnetismHiRes
let hiRes = try MagneticModel.wmmHiRes2025.field(latitude: 37.62, longitude: -122.38)
```

### Errors

`field(…)` throws `MagneticFieldError` for a latitude outside ±90°, a height outside −1 km to
850 km, or a date outside the model's validity period. When WMM2025 expires at the end of 2029,
load NOAA's next coefficient file as a custom model.

## Validation

The tests compare every result against two independent sources:

- **NOAA NCEI's published test values**: the 12-point sets for
  [WMM2025](https://www.ncei.noaa.gov/products/world-magnetic-model) and
  [WMMHR2025](https://www.ncei.noaa.gov/products/world-magnetic-model-high-resolution), and the
  100-point set distributed with the WMM2025 coefficient file. These are included verbatim, and
  results must agree to within each value's printed precision.
- **The British Geological Survey's
  [web service](https://geomag.bgs.ac.uk/web_service/GMModels)**, an independent implementation,
  at the poles, at the edges of the height range, and for calendar dates. Regenerate those points
  with `Scripts/generate-bgs-reference-values.sh`.

## Running Tests

```bash
swift test
```

## Building Documentation

```bash
swift package generate-documentation --target SwiftGeomagnetism
swift package --disable-sandbox preview-documentation --target SwiftGeomagnetism
```

Full documentation is available at
[riscfuture.github.io/SwiftGeomagnetism](https://riscfuture.github.io/SwiftGeomagnetism/).

## Acknowledgments

The World Magnetic Model is produced by NOAA's National Centers for Environmental Information and
the British Geological Survey for the US National Geospatial-Intelligence Agency and the UK
Defence Geographic Centre. Its coefficients are in the public domain. The API was inspired by
[Geomagnetism-Swift](https://github.com/kanchudeep/Geomagnetism-Swift).

## License

SwiftGeomagnetism is released under the MIT License. See [LICENSE.md](LICENSE.md) for details.
